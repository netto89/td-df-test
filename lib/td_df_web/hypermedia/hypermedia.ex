defmodule TdDf.Hypermedia do
  @moduledoc false
  def controller do
    quote do
      import TdDfWeb.Hypermedia.HypermediaControllerHelper
    end
  end

  def view do
    quote do
      import TdDfWeb.Hypermedia.HypermediaViewHelper
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end
