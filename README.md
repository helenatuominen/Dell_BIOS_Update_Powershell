Original updated, just found it on github too
https://deploymentramblings.wordpress.com/2013/05/29/sccm-2012-deploying-dell-bios-updates-using-the-application-model/



From Brooks Peppin [https://deploymentramblings.wordpress.com/2012/06/06/updating-dell-bios-with-powershell-updated/#comment-636]
So I went ahead and took his script and was able to get it working by querying Dell’s site and then download directly from there. The nice part about this is that you don’t have to manage or maintain your own repository. It’s also “self elevating” so people can just right click and “run with powershell” without having to load an elevated powershell prompt first. 
