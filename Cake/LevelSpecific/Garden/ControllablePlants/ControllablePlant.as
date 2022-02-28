import Vino.Camera.Settings.CameraLazyChaseSettings;
import void PlayExitSoilAnimation(AActor) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import void StopEnterSoilAnimation(AActor) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import void PlayExitSoilVFX(AActor, FVector) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import AControllablePlant GetCurrentPlant() from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import void SetCurrentPlant(AControllablePlant, AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import void _OnUnpossessPlant(AHazePlayerCharacter, FVector, FRotator, EControllablePlantExitBehavior) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";

event void FOnExitSoilCompleteSignature();

enum EControllablePlantExitBehavior
{
	// Exit from the soil that was entered in order to become this plant. (Will fallback to PlantLocation if no soil exists).
	ExitSoil,
	// Exit from the location of this plant, wherever the plant is.
	PlantLocation,
	// Useful for plants that traverse inside ground, make sure we place the player on the ground on exit.
	PlantLocationGround,
	// Implement something else somewhere else.
	None
}

UFUNCTION()
void TEST_PossessPlant(AControllablePlant Plant)
{
	Plant.TEST_PossessPlant();
}

UCLASS(Abstract)
class AControllablePlant : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent NetworkSideComponent;
	default NetworkSideComponent.ControlSide = EHazePlayer::Cody;

	UFUNCTION(NetFunction)
	void TEST_PossessPlant()
	{
		PossessPlant(Game::GetCody().ActorLocation, Game::GetCody().ActorRotation);
	}

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachNode;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::High;

	UPROPERTY(Category = Camera)
	UCameraLazyChaseSettings CameraLazyChaseSettings = nullptr;

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet = nullptr;
	bool bHasAddedSheet = false;

	UPROPERTY()
	EHazePlayer DefaultPlayerOwner = EHazePlayer::Cody;

	bool bShowplayerFromPlant = false;

	AActor ActivatingSoil = nullptr;

	AHazePlayerCharacter GetOwnerPlayer() const property 
	{ 
		if(DefaultPlayerOwner == EHazePlayer::Cody)
			return Game::GetCody();

		return Game::GetMay();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(ActivateTimerHandle);
		System::ClearAndInvalidateTimerHandle(DeactivateTimerHandle);

		// Force deactivate if we end the level inside a plant
		if(bIsPlantActive)
		{
			if(!bIsDeactivating)
			{
				BP_OnPreDeactivatePlant();
				PreDeactivate();
			}

			Handle_FinishDeactivation();
		}

		RemovePlayerSheet();
	}

	private FVector _PlayerLocationOnEnter;
	private FRotator _PlayerRotationOnEnter;

	FVector GetPlayerLocationOnEnter() const property { return _PlayerLocationOnEnter; }
	FRotator GetPlayerRotationOnEnter() const property { return _PlayerRotationOnEnter; }

	private FTimerHandle ActivateTimerHandle;
	private FTimerHandle DeactivateTimerHandle;

	// Time it takes for the plant to appear and the player gains control.
	UPROPERTY()
	float AppearTime = 0;

	// Time it takes for the player to exit the plant before control of cody is resumed.
	UPROPERTY()
	float ExitTime = 0;

	bool bWantsToExit = false;
	bool bPlayerIsAttached = false;

	bool GetIsPlantActive() const property { return bIsPlantActive; }

	// Called when instantiating the plant.
	//void InitPlant(AHazePlayerCharacter InPlayer)
	//{
		//SetControlSide(InPlayer);
	//}

	void AddPlayerSheet()
	{
		if(PlayerSheet != nullptr && !bHasAddedSheet)
		{
			bHasAddedSheet = true;
			OwnerPlayer.AddCapabilitySheet(PlayerSheet, Instigator = this);
		}
	}

	void RemovePlayerSheet()
	{
		if(PlayerSheet != nullptr && bHasAddedSheet)
		{
			bHasAddedSheet = false;
			OwnerPlayer.RemoveCapabilitySheet(PlayerSheet, this);
		}
	}

	void StopEnterSoilAnimationOnPlayer()
	{
		StopEnterSoilAnimation(OwnerPlayer);
	}

	void PossessPlantWithCrumbs(FVector InStartLocation, FRotator InStartRotation, AActor InActivatingSoilOwner)
	{
		if(!HasControl())
			return;
		
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddVector(n"StartLocation", InStartLocation);
		CrumbParams.AddVector(n"StartRotation", InStartRotation.Vector());
		if(InActivatingSoilOwner != nullptr)
			CrumbParams.AddObject(n"ActivatingSoilOwner", InActivatingSoilOwner);

		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PossessPlant"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_PossessPlant(FHazeDelegateCrumbData CrumbData)
	{
		FVector NewStartLocation = CrumbData.GetVector(n"StartLocation");
		FRotator NewStartRotation = CrumbData.GetVector(n"StartRotation").Rotation();
		AActor NewActivatingSoil = Cast<AActor>(CrumbData.GetObject(n"ActivatingSoilOwner"));

		PossessPlant(NewStartLocation, NewStartRotation, NewActivatingSoil);
	}

	private bool bIsActivating = false;

	void AttachPlayerToPlant()
	{

	}

	void PossessPlant(FVector InLocation, FRotator InRotation, AActor InActivatingSoil = nullptr)
	{
		AControllablePlant CurrentPlant = GetCurrentPlant();

		if(CurrentPlant != nullptr && CurrentPlant.IsDeactivating())
		{
			CurrentPlant.Handle_FinishDeactivation();
		}

		if(!devEnsure(CurrentPlant == nullptr, "This Player is already controlling another plant."))
			return;

		if(bIsActivating)
			return;

		ActivatingSoil = InActivatingSoil;

		bIsActivating = true;

		_PlayerLocationOnEnter = InLocation;
		_PlayerRotationOnEnter = InRotation;

		TeleportActor(InLocation, InRotation);
		OwnerPlayer.TriggerMovementTransition(this);
		OwnerPlayer.AttachToComponent(PlayerAttachNode);
		//SetControlSide(OwnerPlayer);
		SetCurrentPlant(this, OwnerPlayer);
		bIsPlantActive = true;
		BP_OnPreActivatePlant();
		PreActivate(InLocation, InRotation);

		if(AppearTime > 0.0f)
			ActivateTimerHandle = System::SetTimer(this, n"Handle_FinishActivation", AppearTime, false);
		else
			Handle_FinishActivation();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_FinishActivation()
	{
		System::ClearAndInvalidateTimerHandle(ActivateTimerHandle);
		BP_OnActivatePlant();
		OnActivatePlant();
		bIsActivating = false;
	}

	/* 
		Player will pop out of the plant and the plant will deactivate.
		Called on the plant itself despite eventually being called from the ControllablePlants component because we need to crumb the exit and update references.
	*/
	void ExitPlant()
	{
		if(!HasControl() || !bIsPlantActive)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ExitPlant"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_ExitPlant(FHazeDelegateCrumbData CrumbData)
	{
		// We need to call it from the ControllablePlantsComponent cause it needs to update references.
		UnPossessPlant();
	}

	private bool bIsDeactivating = false;

	bool IsDeactivating() const
	{
		return bIsDeactivating;
	}

	void UnPossessPlant()
	{
		if(!bIsPlantActive)
			return;

		if(bIsActivating)
		{
			Handle_FinishActivation();
		}
		
		if(bIsDeactivating)
			return;

		SetCapabilityActionState(n"OnExitPlant", EHazeActionState::ActiveForOneFrame);
		bIsDeactivating = true;

		BP_OnPreDeactivatePlant();
		PreDeactivate();

		if(ExitTime > 0.0f)
			DeactivateTimerHandle = System::SetTimer(this, n"Handle_FinishDeactivation", ExitTime, false);
		else
			Handle_FinishDeactivation();
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_FinishDeactivation()
	{
		System::ClearAndInvalidateTimerHandle(DeactivateTimerHandle);
		BP_OnDeactivatePlant();
		OnDeactivatePlant();
		bIsDeactivating = false;
		bIsPlantActive = false;
	}

	bool CanExitPlant() const
	{
		return true;
	}

	// Used for lazy chase camera
	FRotator GetTargetRotation() const
	{
		return FRotator::ZeroRotator;
	}

	bool IsMoving() const
	{
		return false;
	}

	void OnUnpossessPlant(FVector InLocation, FRotator InRotation, EControllablePlantExitBehavior InExitBehavior)
	{
		_OnUnpossessPlant(OwnerPlayer, InLocation, InRotation, InExitBehavior);
	}

	void TriggerCameraTransitionToPlayer(){}
	void TriggerCameraTransitionToPlant(){}

	// Called from ControllablePlantsComponent. Should implement DisableAndHidePlayer. Left empty on purpose for you to override and implement.
	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) {}

	// Override and implement plant-specific stuff that will happen once it activates. Called when AppearTime has elapsed.
	void OnActivatePlant(){}

	void PreDeactivate() {}

	// Override and implement plant-specific stuff that will happen once it deactivates. Called when ExitTime has elapsed.
	void OnDeactivatePlant(){}

	bool bIsPlantActive = false;

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On PreDeactivate Plant"))
	void BP_OnPreDeactivatePlant() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Deactivate Plant"))
	void BP_OnDeactivatePlant() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On PreActivate Plant"))
	void BP_OnPreActivatePlant() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Activate Plant"))
	void BP_OnActivatePlant() {}
}
