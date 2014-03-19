package gama
{
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;

	/**
	 * 将这个助手类和 AssetsHelper 独立开是为了避免在 Flash Player 中初始化 File 相关的类，从而导致运行时出错
	 * @author ty
	 *
	 */
	public class FileHelper
	{

		static private const ASSET_FILE_EXT:String = Environment.ASSET_FILE_EXT ;

		static private const _FILE_CACHE_FOLDER_NAME:String = 'bin';

		static private const DEPOT_FOLDER:File = File.applicationStorageDirectory.resolvePath(_FILE_CACHE_FOLDER_NAME) ;

		static internal function getFileForWuid(wuid:String):File
		{
			return DEPOT_FOLDER.resolvePath( wuid.charAt(0) + SLASH + wuid + ASSET_FILE_EXT);
		}

		static private const SLASH:String = '/' ;

		/**
		 * 检查一个wuid所对应的文件缓存是否存在
		 * @param wuid
		 * @return
		 */
		static internal function isFileCacheExsit(wuid:String):Boolean
		{
			if(wuid == null) return false;
			if(WUID_ALEADY_CACHED[wuid] === FileHelper) return true;
			var f:File = DEPOT_FOLDER.resolvePath( wuid.charAt(0) + SLASH + wuid + ASSET_FILE_EXT)
			if(f.exists)
			{ /* 加入注册清单 */
				WUID_ALEADY_CACHED[wuid] = FileHelper;
				return true;
			}
			return false;
		}

		/**
		 * 返回 app-storage 协议的本地文件缓存地址
		 * @param wuid
		 * @return
		 */
		static public function generateFileCacheUrl(wuid:String):String
		{
			return "app-storage:/"+_FILE_CACHE_FOLDER_NAME+SLASH+wuid.charAt(0) + SLASH + wuid + ASSET_FILE_EXT;
		}

		/**
		 * 删除给定 wuid 的本地文件缓存
		 * @param wuid
		 */
		static public function deleteFileCache(wuid:String):void
		{
			if(wuid == null)
			{
				trace("ERROR [FileHelper.deleteFileCache] bad request");
				return;
			}
			delete WUID_ALEADY_CACHED[wuid];
			var f:File = DEPOT_FOLDER.resolvePath( wuid.charAt(0) + SLASH + wuid + ASSET_FILE_EXT);
			if(f.exists)
			{
				try{
					f.deleteFile();
				}
				catch(e:Error)
				{
					trace("!!! ERROR [FileHelper.deleteFileCache] 删除文件时发生错误: "+e);
				}
			}
		}

		/**
		 * 记录已经 check exists 并且发现存在的 wuid
		 *
		 * NOTE: 将 WUID_ALEADY_CACHED 从 FileDepositerManager 中移到 Helper 中来的目的是为了在 FileDepositerManager 和 FileWithdrawerManager 中共享信息
		 */
		static internal var WUID_ALEADY_CACHED:Dictionary = new Dictionary ;


		static private var directoryAsset:File ;

		/**
		 * 需要显性初始化以挂钩到 StreamManager
		 */
		static public function init():void
		{
			FileDepositerManager.init();
			// FileWithdrawerManager.init();
			// LoadJob.fileCacheDeleteCall = deleteFileCache;
			// AssetsManager.isFileCacheExsit = isFileCacheExsit;
			// Streamer.dirPreinstalledAssets = dirPreinstalledAssets;
		}

		/**
		 * 随应用程序一同安装时的 data 模块
		 */
		static private const APP_ASSET_PATH:String = "./data/" ;

		/**
		 * 检查预装目录下的素材
		 */
		static private function dirPreinstalledAssets():void
		{
			directoryAsset = File.applicationDirectory.resolvePath(APP_ASSET_PATH);
			directoryAsset.addEventListener(FileListEvent.DIRECTORY_LISTING, resultOfAssetDir);
			directoryAsset.addEventListener(IOErrorEvent.IO_ERROR, resultOfAssetDir);
			directoryAsset.addEventListener(SecurityErrorEvent.SECURITY_ERROR, resultOfAssetDir);
			directoryAsset.getDirectoryListingAsync();
		}

		/**
		 * 当异步从安装目录的 data 目录下拉出目录列表的时候
		 */
		static private function resultOfAssetDir(event:Event):void
		{
			directoryAsset.removeEventListener(FileListEvent.DIRECTORY_LISTING, resultOfAssetDir);
			directoryAsset.removeEventListener(IOErrorEvent.IO_ERROR, resultOfAssetDir);
			directoryAsset.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, resultOfAssetDir);

			if(event.type == FileListEvent.DIRECTORY_LISTING)
			{ /* 成功得到数据目录 */
				var list:Array = (event as FileListEvent).files;
				var fileName:String;
				var charLengthOfExtension:uint = ASSET_FILE_EXT.length;

				var preInstalledAssetWuids:Object = Streamer.ASSET_WUIDS_WITH_INSTALLATION;

				var count:uint = 0;

				/* 将 随程序安装的预置素材的wuid读入 */
				for each (var file:File in list)
				{
					fileName = file.name;
					if(fileName.substr(fileName.length - charLengthOfExtension, charLengthOfExtension) === ASSET_FILE_EXT)
					{
						/**
						 * NOTE:
						 *  先判断 length 再做字符串操作，这样比较快
						 *
						 * ty Jul 21, 2012
						 */
						trace("[Rects] found pre-installed asset, wuid:"+fileName);
						preInstalledAssetWuids[fileName.substr(0, fileName.length - charLengthOfExtension)] = Streamer;
						count++;
					}
				}
			}

			/* 回收掉 directoryAsset */
			directoryAsset = null;

			trace("[Rects] found "+count+" pre-installed assets.");
			// StreamerManager.initByDirPreinstalledAssetsFromHelper();
		}
	}
}
