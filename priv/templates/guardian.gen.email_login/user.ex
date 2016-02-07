defmodule <%= base %>.User do
  use <%= base %>.Web, :model

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true

    timestamps
  end

  @fields ~w(email password)

  def from_email(nil), do: { :error, :not_found }
  def from_email(query \\ __MODULE__, email) do
    from u in query, where: u.email == ^email
  end

  def save_changeset(model), do: model |> cast(%{}, ~w(), @fields)
  def save_changeset(model, params) do
    model
    |> cast(params, @fields,  ~w())
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 5)
    |> maybe_update_password
  end

  def login_changeset(model), do: model |> cast(%{}, ~w(), @fields)
  def login_changeset(model, params) do
    model
    |> cast(params, ~w(email password), ~w())
    |> validate_password
  end

  def valid_password?(nil, _), do: false
  def valid_password?(_, nil), do: false
  def valid_password?(password, crypted), do: Comeonin.Bcrypt.checkpw(password, crypted)

  defp maybe_update_password(changeset) do
    case Ecto.Changeset.fetch_change(changeset, :password) do
      { :ok, password } ->
        changeset
        |> Ecto.Changeset.put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      :error -> changeset
    end
  end

  defp validate_password(changeset) do
    case Ecto.Changeset.get_field(changeset, :encrypted_password) do
      nil -> password_incorrect_error(changeset)
      crypted -> validate_password(changeset, crypted)
    end
  end

  defp validate_password(changeset, crypted) do
    password = Ecto.Changeset.get_change(changeset, :password)
    if valid_password?(password, crypted), do: changeset, else: password_incorrect_error(changeset)
  end

  defp password_incorrect_error(changeset), do: Ecto.Changeset.add_error(changeset, :password, "is incorrect")
end
