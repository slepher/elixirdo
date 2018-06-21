defmodule Elixirdo.Base.Utils.File do

  def extract_matching_by_attribute(paths, prefix, callback) do
    for path <- paths,
        file <- list_dir(path),
        mod = extract_from_file(path, file, prefix, callback),
        do: mod
  end

  def list_dir(path) when is_list(path) do
    case :file.list_dir(path) do
      {:ok, files} -> files
      _ -> []
    end
  end

  def list_dir(path), do: list_dir(to_charlist(path))

  def extract_from_file(path, file, prefix, callback) do
    if :lists.prefix(prefix, file) and :filename.extension(file) == '.beam' do
      extract_from_beam(:filename.join(path, file), callback)
    end
  end

  def extract_from_beam(file, callback) do
    case :beam_lib.chunks(file, [:attributes]) do
      {:ok, {module, [attributes: attributes]}} ->
        callback.(module, attributes)

      _ ->
        nil
    end
  end

  def beams(paths, prefix) do
    for path <- paths,
        file <- list_dir(path),
        :filename.extension(file) == '.beam',
        :lists.prefix(prefix, file),
        do: :filename.join(path, file)
  end
end
