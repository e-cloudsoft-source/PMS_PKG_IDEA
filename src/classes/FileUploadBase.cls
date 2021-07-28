/**
* ファイルアップロード基本クラス
**/
public virtual class FileUploadBase {
    private String fileName;
    private Integer fileSize;
    private Blob fileBody;
    private Integer maxFileSize;
    public FileUploadBase()
    {
        maxFileSize = (0.9 * 1024 * 1024).intValue();
    }
    public String getFileName() {
        return this.fileName;
    }
    public void setFileName(String fileName)    {
        this.fileName = fileName;
    }
    public Blob getFileBody()   {
        return this.fileBody;
    }
    public void setFileBody(Blob fileBody)  {
        this.fileBody = fileBody;
        this.setFileSize(this.fileBody.size());
    }
    public Integer getFileSize()    {
        return this.fileSize;
    }
    public void setFileSize(Integer fileSize)   {
        this.fileSize = fileSize;
    }
    /*
    // 最大アップロードファイルサイズ:Byte単位で
    public void setMaxFileSize (Integer maxFileSizeByKb) {
        this.maxFileSize = maxFileSizeByKb;
    }
    public Integer getMaxFileSize() {
        return this.maxFileSize;
    }
    // Attachmentにファイルインサーとする
    public virtual Database.SaveResult insertAttachment(Id parentId) {

        Database.SaveResult result;
        Attachment attachment = new Attachment();
        attachment.Body = this.fileBody;
        attachment.Name = this.fileName;
        attachment.ParentId = parentId;
        result = Database.insert(attachment);
        fileBody = Blob.valueOf('  ');
        return result;
    }*/

    public void clear() {
        this.fileName = '';
        this.fileBody = Blob.valueOf('  ');
    }
}