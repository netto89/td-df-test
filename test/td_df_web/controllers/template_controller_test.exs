defmodule TdDfWeb.TemplateControllerTest do
  use TdDfWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdDfWeb.Authentication, only: :functions

  alias Poison, as: JSON
  #alias TdDf.Accounts.User
  alias TdDf.Permissions.MockPermissionResolver
  
  alias TdDf.Templates
  alias TdDf.Templates.Template
  alias TdDfWeb.ApiServices.MockTdAuthService

  @create_attrs %{content: [], label: "some name", name: "some_name", is_default: false}
  @generic_attrs %{
    content: [%{type: "type1", required: true, name: "name1", max_size: 100}],
    label: "generic true",
    name: "generic_true",
    is_default: false
  }
  @create_attrs_generic_true %{
    content: [%{includes: ["generic_true"]}, %{other_field: "other_field"}],
    label: "some name",
    name: "some_name",
    is_default: false
  }
  @create_attrs_generic_false %{
    content: [%{includes: ["generic_false"]}, %{other_field: "other_field"}],
    label: "some name",
    name: "some_name",
    is_default: false
  }
  @others_create_attrs_generic_true %{
    content: [%{includes: ["generic_true", "generic_false"]}, %{other_field: "other_field"}],
    label: "some name",
    name: "some_name",
    is_default: false
  }
  @update_attrs %{content: [], label: "some updated name", name: "some_name", is_default: false}
  @invalid_attrs %{content: nil, label: nil,  name: nil}

  def fixture(:template) do
    {:ok, template} = Templates.create_template(@create_attrs)
    template
  end

  setup_all do
    start_supervised(MockPermissionResolver)
    start_supervised(MockTdAuthService)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all templates", %{conn: conn, swagger_schema: schema} do
      conn = get(conn, template_path(conn, :index))
      validate_resp_schema(conn, schema, "TemplatesResponse")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create template" do
    @tag :admin_authenticated
    test "renders template when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, template_path(conn, :create), template: @create_attrs)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :show, id))
      validate_resp_schema(conn, schema, "TemplateResponse")

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "content" => [],
               "is_default" => false,
               "label" => "some name",
               "name" => "some_name"
             }
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, template_path(conn, :create), template: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "renders template with valid includes", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, template_path(conn, :create), template: @generic_attrs)
      validate_resp_schema(conn, schema, "TemplateResponse")

      conn = recycle_and_put_headers(conn)
      conn = post(conn, template_path(conn, :create), template: @create_attrs_generic_true)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :load_and_show, id))
      validate_resp_schema(conn, schema, "TemplateResponse")

      assert JSON.encode(json_response(conn, 200)["data"]) ==
               JSON.encode(%{
                 "id" => id,
                 "content" => [
                   %{other_field: "other_field"},
                   %{type: "type1", required: true, name: "name1", max_size: 100}
                 ],
                 "is_default" => false,
                 "label" => "some name",
                 "name" => "some_name"
               })
    end

    @tag :admin_authenticated
    test "renders template with invalid includes", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, template_path(conn, :create), template: @generic_attrs)
      validate_resp_schema(conn, schema, "TemplateResponse")

      conn = recycle_and_put_headers(conn)
      conn = post(conn, template_path(conn, :create), template: @create_attrs_generic_false)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :load_and_show, id))
      validate_resp_schema(conn, schema, "TemplateResponse")

      assert JSON.encode(json_response(conn, 200)["data"]) ==
               JSON.encode(%{
                 "id" => id,
                 "content" => [%{other_field: "other_field"}],
                 "is_default" => false,
                 "label" => "some name",
                 "name" => "some_name"
               })
    end

    @tag :admin_authenticated
    test "renders template with valid and invalid includes", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, template_path(conn, :create), template: @generic_attrs)
      validate_resp_schema(conn, schema, "TemplateResponse")

      conn = recycle_and_put_headers(conn)
      conn = post(conn, template_path(conn, :create), template: @others_create_attrs_generic_true)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :load_and_show, id))
      validate_resp_schema(conn, schema, "TemplateResponse")

      assert JSON.encode(json_response(conn, 200)["data"]) ==
               JSON.encode(%{
                 "id" => id,
                 "content" => [
                   %{other_field: "other_field"},
                   %{type: "type1", required: true, name: "name1", max_size: 100}
                 ],
                 "is_default" => false,
                 "label" => "some name",
                 "name" => "some_name"
               })
    end
  end

  describe "update template" do
    setup [:create_template]

    @tag :admin_authenticated
    test "renders template when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      template: %Template{id: id} = template
    } do
      conn = put(conn, template_path(conn, :update, template), template: @update_attrs)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :show, id))
      validate_resp_schema(conn, schema, "TemplateResponse")

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "content" => [],
               "is_default" => false,
               "label" => "some updated name",
               "name" => "some_name"
             }
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, template: template} do
      conn = put(conn, template_path(conn, :update, template), template: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete template" do
    setup [:create_template]

    @tag :admin_authenticated
    test "deletes chosen template", %{conn: conn, template: template} do
      conn = delete(conn, template_path(conn, :delete, template))
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)

      assert_error_sent(404, fn ->
        get(conn, template_path(conn, :show, template))
      end)
    end
  end

  # @tag authenticated_user: "user_name"
  # test "get domain templates. Check role meta", %{conn: conn, swagger_schema: schema} do
  #   role_name = "role_name"

  #   template =
  #     insert(
  #       :template,
  #       content: [
  #         %{
  #           name: "dominio",
  #           type: "list",
  #           label: "label",
  #           values: [],
  #           required: false,
  #           form_type: "dropdown",
  #           description: "description",
  #           meta: %{role: role_name}
  #         }
  #       ]
  #     )

  #   role = MockTdAuthService.find_or_create_role(role_name)

  #   parent_domain = insert(:domain, templates: [template])
  #   {:ok, child_domain} = build(:child_domain, parent: parent_domain)
  #     |> Map.put(:parent_id, parent_domain.id)
  #     |> Map.take([:name, :description, :parent_id])
  #     |> Taxonomies.create_domain

  #   group_name = "group_name"
  #   group = MockTdAuthService.create_group(%{"group" => %{"name" => group_name}})
  #   group_user_name = "group_user_name"

  #   MockTdAuthService.create_user(%{
  #     "user" => %{
  #       "user_name" => group_user_name,
  #       "full_name" => "#{group_user_name}",
  #       "is_admin" => false,
  #       "password" => "password",
  #       "email" => "nobody@bluetab.net",
  #       "groups" => [%{"name" => group_name}]
  #     }
  #   })

  #   user_name = "user_name"

  #   MockPermissionResolver.create_acl_entry(%{
  #     principal_id: group.id,
  #     principal_type: "group",
  #     resource_id: parent_domain.id,
  #     resource_type: "domain",
  #     role_id: role.id
  #   })

  #   MockPermissionResolver.create_acl_entry(%{
  #     principal_id: User.gen_id_from_user_name(user_name),
  #     principal_type: "user",
  #     resource_id: child_domain.id,
  #     resource_type: "domain",
  #     role_id: role.id
  #   })

  #   conn =
  #     get(conn, template_path(conn, :get_domain_templates, child_domain.id, preprocess: true))

  #   validate_resp_schema(conn, schema, "TemplatesResponse")
  #   stored_templates = json_response(conn, 200)["data"]

  #   values =
  #     stored_templates
  #     |> Enum.at(0)
  #     |> Map.get("content")
  #     |> Enum.at(0)
  #     |> Map.get("values")

  #   default =
  #     stored_templates
  #     |> Enum.at(0)
  #     |> Map.get("content")
  #     |> Enum.at(0)
  #     |> Map.get("default")

  #   assert values |> Enum.sort == [group_user_name, user_name] |> Enum.sort
  #   assert default == user_name
  # end

  defp create_template(_) do
    template = fixture(:template)
    {:ok, template: template}
  end
end
