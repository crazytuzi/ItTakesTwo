import Vino.Interactions.OneShotInteraction;
import Cake.LevelSpecific.Clockwork.ClockTown.ClockTownPigHatch;

event void FClockTownPigTroughEvent();

UCLASS(Abstract)
class AClockTownPigTrough : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TroughRoot;

	UPROPERTY(DefaultComponent, Attach = TroughRoot)
	UStaticMeshComponent TroughMesh;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	AActor PointOfInterest;

	UPROPERTY()
	AOneShotInteraction TargetInteraction;

	UPROPERTY()
	AClockTownPigHatch Hatch;

	UPROPERTY(NotVisible)
	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TroughMesh.SetCullDistance(Editor::GetDefaultCullingDistance(TroughMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetInteraction.OnOneShotActivated.AddUFunction(this, n"OneShotActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void OneShotActivated(AHazePlayerCharacter Player, AOneShotInteraction Interaction)
	{
		Interaction.DisableInteraction(n"Moved");

		TargetPlayer = Player;

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = PointOfInterest;
		TargetPlayer.ApplyPointOfInterest(PoI, this);
		TargetPlayer.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(2.f), this);

		TargetPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
		


		System::SetTimer(this, n"MoveTrough", 0.5f, false);
	}

	UFUNCTION()
	void MoveTrough()
	{
		BP_MoveTrough();
		System::SetTimer(this, n"HideCarrots", 2.f, false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_MoveTrough() {}

	UFUNCTION(NotBlueprintCallable)
	void HideCarrots()
	{
		BP_HideCarrots();
		Hatch.StartHatchSequence();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HideCarrots() {}

	UFUNCTION()
	void EnableMovementInput()
	{
		TargetPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION()
	void ClearCameraSettings()
	{
		TargetPlayer.ClearPointOfInterestByInstigator(this);
		TargetPlayer.ClearCameraSettingsByInstigator(this);
	}
}