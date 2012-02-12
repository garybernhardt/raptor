require "raptor"

describe Raptor::BuildsRoutes do
  it "errors when asked to create guess a presenter for a root URL like GET /" do
    app_module = Module.new
    expect do
      Raptor::BuildsRoutes.new(app_module).index
    end.to raise_error(Raptor::CantInferModulePathsForRootRoutes)
  end
end

