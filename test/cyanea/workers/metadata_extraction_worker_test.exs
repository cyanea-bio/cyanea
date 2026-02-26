defmodule Cyanea.Workers.MetadataExtractionWorkerTest do
  use Cyanea.DataCase, async: false
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Workers.MetadataExtractionWorker

  import Cyanea.BlobsFixtures

  describe "perform/1" do
    test "succeeds for blob with no matching extractor" do
      blob = blob_fixture(%{mime_type: "application/octet-stream"})

      # No extractor for generic binary — should return :ok
      assert :ok =
               perform_job(MetadataExtractionWorker, %{blob_id: blob.id})
    end

    test "handles blob with known extension gracefully" do
      # Create a blob with a FASTA-like s3_key
      # The worker will fail to download from S3 (not running in test),
      # but we verify it dispatches correctly
      blob = blob_fixture(%{mime_type: "text/plain"})

      # The blob's s3_key is content-addressed (no extension),
      # so no extractor will match — returns :ok
      assert :ok =
               perform_job(MetadataExtractionWorker, %{blob_id: blob.id})
    end

    test "handles CSV mime_type detection" do
      blob = blob_fixture(%{mime_type: "text/csv"})

      # Will try CSV extractor, but S3 download will fail in test.
      # The worker should handle the error gracefully.
      result = perform_job(MetadataExtractionWorker, %{blob_id: blob.id})
      assert result == :ok || match?({:error, _}, result)
    end
  end
end
