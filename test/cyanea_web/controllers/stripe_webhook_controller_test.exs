defmodule CyaneaWeb.StripeWebhookControllerTest do
  use CyaneaWeb.ConnCase, async: false

  describe "POST /webhooks/stripe" do
    test "returns 400 for invalid signature", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("stripe-signature", "invalid_signature")
        |> post("/webhooks/stripe", Jason.encode!(%{type: "test"}))

      assert json_response(conn, 400)["error"] == "Invalid signature"
    end

    test "returns 400 when no signature header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/webhooks/stripe", Jason.encode!(%{type: "test"}))

      assert json_response(conn, 400)["error"] == "Invalid signature"
    end
  end
end
