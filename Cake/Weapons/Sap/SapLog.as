void SapLog(FString Msg)
{
	FString Prefix;
	if (Network::IsNetworked())
		Prefix = Game::Cody.HasControl() ? "[CODY] " : "[MAY ] ";

	Log(Prefix + Msg);
}