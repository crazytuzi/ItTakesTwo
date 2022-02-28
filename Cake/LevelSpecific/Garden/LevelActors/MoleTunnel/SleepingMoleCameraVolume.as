import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.SleepingMole;

// Player spring arm will ignore collision against moles inside volume when entered.
class ASleepingMoleCameraVolume : AHazeCameraVolume
{
	default CameraSettings.Player = EHazeSelectPlayer::Cody;

	UPROPERTY(Category = Moles)
	TArray<ASleepingMole> Moles;

	UFUNCTION(CallInEditor, NotBlueprintCallable, Category = Moles)
	private void RefreshMoles()
	{
		Moles.Empty(Moles.Num());
		TArray<ASleepingMole> AllMoles;
		GetAllActorsOfClass(ASleepingMole::StaticClass(), AllMoles);
		for (ASleepingMole Mole : AllMoles)
		{
			if (EncompassesPoint(Mole.ActorLocation, 100.f))
				Moles.Add(Mole);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Moles.Num() == 0)
			RefreshMoles();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnVolumeActivated.AddUFunction(this, n"VolumeActivated");
		OnVolumeDeactivated.AddUFunction(this, n"VolumeDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		OnVolumeActivated.Unbind(this, n"VolumeActivated");
		OnVolumeDeactivated.Unbind(this, n"VolumeDeactivated");
	}

	UFUNCTION()
	private void VolumeActivated(UHazeCameraUserComponent User)
	{
		if (User == nullptr)
			return;

		UHazeCameraComponent DefaultCamera = UHazeCameraComponent::Get(User.Owner);
		if (DefaultCamera != nullptr)
		{
			for (ASleepingMole Mole : Moles)
			{
				DefaultCamera.CameraCollisionParams.AdditionalIgnoreActors.AddUnique(Mole);
			}
		}
	}

	UFUNCTION()
	private void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		if (User == nullptr)
			return;

		UHazeCameraComponent DefaultCamera = UHazeCameraComponent::Get(User.Owner);
		if (DefaultCamera != nullptr)
		{
			for (ASleepingMole Mole : Moles)
			{
				DefaultCamera.CameraCollisionParams.AdditionalIgnoreActors.Remove(Mole);
			}
		}
	}
}
