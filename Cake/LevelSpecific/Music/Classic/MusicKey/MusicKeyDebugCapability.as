import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;

class UMusicKeyDebugCapability : UHazeDebugCapability
{
	UPROPERTY()
	TSubclassOf<AMusicalFollowerKey> KeyClass;

	private bool bDrawLocation = false;
	private AHazePlayerCharacter Player;

	private int NetworkSpawnCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler DrawLocationsHandler = DebugValues.AddFunctionCall(n"ToggleDrawLocations", "Draw Key Locations");
		FHazeDebugFunctionCallHandler SpawnKeyHandler = DebugValues.AddFunctionCall(n"SpawnMusicKey", "Spawn Music Key");
		FHazeDebugFunctionCallHandler RemoveKeyHandler = DebugValues.AddFunctionCall(n"RemoveMusicKey", "Remove Music Key");

		DrawLocationsHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"MusicKey");
		SpawnKeyHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"MusicKey");
		RemoveKeyHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"MusicKey");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION()
	private void ToggleDrawLocations()
	{
		bDrawLocation = !bDrawLocation;
	}

	UFUNCTION()
	private void SpawnMusicKey()
	{
		if(!HasControl())
			return;

		if(!KeyClass.IsValid())
			return;

		NetSpawnMusicKey();
	}

	UFUNCTION(NetFunction)
	private void NetSpawnMusicKey()
	{
		AMusicalFollowerKey NewKey = Cast<AMusicalFollowerKey>(SpawnActor(KeyClass, Player.ActorCenterLocation, FRotator::ZeroRotator, bDeferredSpawn = true));
		NewKey.SetControlSide(Player);
		NewKey.MakeNetworked(this, NetworkSpawnCount);
		NetworkSpawnCount++;
		FinishSpawningActor(NewKey);
		NewKey.AddPendingFollowTarget(Player);
	}

	UFUNCTION()
	private void RemoveMusicKey()
	{
		if(!HasControl())
			return;

		UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(Owner);

		if(KeyComp == nullptr)
			return;

		AMusicalFollowerKey KeyToRemove = KeyComp.FirstKey;

		if(KeyToRemove == nullptr)
			return;

		KeyToRemove.DestroyKey();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawLocation)
			DrawKeyLocations();
	}

	private void DrawKeyLocations()
	{
		UHazeAITeam KeyTeam = HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam");

		if(KeyTeam == nullptr)
			return;

		TSet<AHazeActor> Members = KeyTeam.Members;
		for(AHazeActor KeyActor : Members)
		{
			System::DrawDebugSphere(KeyActor.ActorCenterLocation, 300.0f, 16, FLinearColor::Green, 0, 8.0f);
		}
	}
}
