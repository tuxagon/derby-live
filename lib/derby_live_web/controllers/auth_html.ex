defmodule DerbyLiveWeb.AuthHTML do
  use DerbyLiveWeb, :html

  embed_templates "auth_html/*"

  attr :form, Map, required: true
  attr :action, :string, required: true
  def login_form(assigns)
end
