import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantProjectile;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Peanuts.Animation.Features.Garden.LocomotionFeatureDandelionFlight;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.LevelSpecific.Garden.ControllablePlants.SoilState;
import Vino.Tutorial.TutorialPrompt;



UFUNCTION()
void PossessPlant(AHazePlayerCharacter Player, AControllablePlant PlantToPossess, FVector InLocation, FRotator InRotation)
{
	if(PlantToPossess == nullptr)
		return;

	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Player);
	if(PlantsComp != nullptr)
	{
		PlantsComp.OnPossessPlant(PlantToPossess);
		PlantToPossess.PossessPlant(InLocation, InRotation);
	}
}

void _OnUnpossessPlant(AHazePlayerCharacter InPlayer, FVector InLocation, FRotator InRotation, EControllablePlantExitBehavior ExitBehavior)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(InPlayer);
	if(PlantsComp != nullptr)
	{
		PlantsComp.OnUnpossessPlant(InLocation, InRotation, ExitBehavior);
	}
}

void ActivateSubmersibleSoilComponent(USubmersibleSoilComponent SoilComponent, AHazePlayerCharacter Player)
{
	auto PlantsComp = UControllablePlantsComponent::Get(Player);
	PlantsComp.ActivatingSoil = SoilComponent;
	PlantsComp.bEnterSoil = true;
}

void SetCanExitSoil(AHazePlayerCharacter Player, bool bCanExitSoil)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Player);
	PlantsComp.bCanExitSoil = bCanExitSoil;
}

USubmersibleSoilComponent GetActivatingSoilComponentFromPlayer(AHazePlayerCharacter PlayerCharacter)
{
	auto PlantsComp = UControllablePlantsComponent::Get(PlayerCharacter);
	return PlantsComp.ActivatingSoil;
}

void PlayExitSoilAnimation(AActor Actor)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Actor);

	if(PlantsComp != nullptr)
	{
		PlantsComp.PlayExitSoilAnimation();
	}
}

void StopEnterSoilAnimation(AActor Actor)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Actor);

	if(PlantsComp != nullptr)
	{
		PlantsComp.StopEnterSoilAnimation();
	}
}

void PlayExitSoilVFX(AActor Owner, FVector Location)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Owner);

	if(PlantsComp != nullptr && PlantsComp.ExitSoilVFX != nullptr)
	{
		Niagara::SpawnSystemAtLocation(PlantsComp.ExitSoilVFX, Location);
	}
}

void SetCurrentPlant(AControllablePlant InControllablePlant, AHazePlayerCharacter InPlayer)
{
	ensure(InControllablePlant != nullptr);
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(InPlayer);

	if(PlantsComp != nullptr)
	{
		PlantsComp.CurrentPlant = InControllablePlant;
		if(InControllablePlant != nullptr)
		{	
			if(InControllablePlant.ActivatingSoil != nullptr)
			{
				PlantsComp.ActivatingSoil = USubmersibleSoilComponent::Get(InControllablePlant.ActivatingSoil);

				FPlayerSubmergedInSoilInfo EventParams;
				EventParams.Player = InPlayer;
				EventParams.ControlledPlant = InControllablePlant;
				EventParams.Soil = PlantsComp.ActivatingSoil;
				EventParams.BroadcastEnter();
				EventParams.Soil.OnPlayerEnterSoil.Broadcast(InPlayer);	
			}

			PlantsComp.OnPossessPlant(InControllablePlant);
		}
	}
}

// Returns the currently active plant from codys ControllablePlantsComponent. This can be null so be sure to check if valid.
UFUNCTION(BlueprintPure)
AControllablePlant GetCurrentPlant()
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Game::GetCody());

	if(PlantsComp != nullptr)
	{
		return PlantsComp.CurrentPlant;
	}

	return nullptr;
}

ASubmersibleSoil GetActivatingSoil(AActor Owner)
{
	UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Owner);

	if(PlantsComp != nullptr && PlantsComp.ActivatingSoil != nullptr)
	{
		return Cast<ASubmersibleSoil>(PlantsComp.ActivatingSoil.Owner);
	}

	return nullptr;
}

UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Activation Variable Cooking Tags AssetUserData Collision")
class UControllablePlantsComponent : UActorComponent
{
	TArray<AControllablePlant> AvailablePlants;

	UPROPERTY(Category = Animation)
	UAnimSequence EnterSoilAnim;

	UPROPERTY(Category = Animation)
	UAnimSequence ExitSoilAnim;

	UPROPERTY(Category = VFX)
	UNiagaraSystem EnterSoilVFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem ExitSoilVFX;

	UPROPERTY(Category = "Events")
	FOnExitSoilCompleteSignature OnExitSoilComplete;

	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AControllablePlant CurrentPlant;
	
	UHazeCrumbComponent CrumbComp;

	USubmersibleSoilComponent ActivatingSoil;
	private USubmersibleSoilComponent InternalLinkedActivatingSoil;
	private int LinkedSoilCounter = 0;

	FVector DefaultPlantLoc = FVector(0.f, 0.f, -800.f);

	// Set this class to anything and the associated capability (ActivatePlantCapability) will trigger ActivatePlant.
	private TSubclassOf<AControllablePlant> _TargetPlantClass;

	int SpawnCounter;

	bool bCanExitSoil = true;
	bool bDeactivatePlant = false;
	bool bEnterSoil = false;
	FTutorialPrompt ExitTutorial;



	FVector EnterSoilLocation;

	FTimerHandle AppearTimerHandle;
	FTimerHandle ExitTimerHandle;

	bool bHasPlayerBlocksActive = false;
	bool bHasPlayerVisibilityChangeActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(AControllablePlant Plant : AvailablePlants)
		{
			if(Plant == nullptr)
				continue;

			Plant.DestroyActor();
		}

		AvailablePlants.Empty();

		System::ClearAndInvalidateTimerHandle(AppearTimerHandle);
		System::ClearAndInvalidateTimerHandle(ExitTimerHandle);

		// Safety cleanup
		SetPlayerBlocks(false);
		SetPlayerHidden(false);
	}

	AControllablePlant SpawnNewPlantActor(TSubclassOf<AControllablePlant> PlantClassToSpawn)
	{
		AControllablePlant NewPlantInstance = Cast<AControllablePlant>(SpawnPersistentActor(PlantClassToSpawn, DefaultPlantLoc, bDeferredSpawn = true));
		NewPlantInstance.MakeNetworked(this, SpawnCounter);
		SpawnCounter++;
		//NewPlantInstance.InitPlant(Player);
		FinishSpawningActor(NewPlantInstance);
		AvailablePlants.Add(NewPlantInstance);
		return NewPlantInstance;
	}

	void ActivatePlant(TSubclassOf<AControllablePlant> PlantClass)
	{
		if(!HasControl())
			return;

		if(!devEnsure(PlantClass.IsValid(), "Invalid plant class"))
			return;
	
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"PlantClass", PlantClass.Get());
		CrumbParams.AddVector(n"PlayerLocation", Owner.ActorLocation);
		CrumbParams.AddVector(n"PlayerRotation", Owner.ActorRotation.Vector());
		if(ActivatingSoil != nullptr)
			CrumbParams.AddObject(n"ActivatingSoil", ActivatingSoil);	
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ActivatePlant"), CrumbParams);
	}

	void ActivatePlant_Local(TSubclassOf<AControllablePlant> PlantClass, FTransform ActivationTransform, USubmersibleSoilComponent FromSoil = nullptr)
	{
		if(!devEnsure(PlantClass.IsValid(), "Invalid plant class"))
			return;

		PlantToActivate = FindInstanceFromClassType(PlantClass);

		bool bSpawnNewPlant = false;

		if(PlantToActivate == nullptr)
		{
			PlantToActivate = SpawnNewPlantActor(PlantClass);
			bSpawnNewPlant = true;
		}
			
		if(!devEnsure(PlantToActivate != nullptr, "Unable to locate or spawn plant class: " + PlantClass.Get().DefaultObject.Name))
			return;

		AActor ActivatingSoilOwner = nullptr;
		if(FromSoil != nullptr)
		{
			ActivatingSoilOwner = FromSoil.Owner;
		}

		const FVector StartLocation = ActivationTransform.GetLocation();
		const FRotator StartRotation = ActivationTransform.Rotator();

		if(bSpawnNewPlant)
			PlantToActivate.PossessPlant(StartLocation, StartRotation, ActivatingSoilOwner);
		else
			PlantToActivate.PossessPlantWithCrumbs(StartLocation, StartRotation, ActivatingSoilOwner);
	}

	private AControllablePlant PlantToActivate = nullptr;

	UFUNCTION()
	private void Crumb_ActivatePlant(FHazeDelegateCrumbData CrumbData)
	{
		TSubclassOf<AControllablePlant> PlantClass = Cast<UClass>(CrumbData.GetObject(n"PlantClass"));
		USubmersibleSoilComponent SoilComp = Cast<USubmersibleSoilComponent>(CrumbData.GetObject(n"ActivatingSoil"));
		FTransform ActivationTransform(CrumbData.GetVector(n"PlayerRotation").Rotation(), CrumbData.GetVector(n"PlayerLocation"));
		ActivatePlant_Local(PlantClass, ActivationTransform, SoilComp);
	}

	void OnPossessPlant(AControllablePlant InPlant)
	{
		SetPlayerHidden(true);
		SetPlayerBlocks(true);
	}

	void SetPlayerBlocks(bool bStatus)
	{
		if(bHasPlayerBlocksActive == bStatus)
			return;

		bHasPlayerBlocksActive = bStatus;
		if(bStatus)
		{
			Player.BlockCapabilities(CapabilityTags::Collision, this);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
			Player.DisableMovementComponent(this);
		}
		else
		{
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
			Player.EnableMovementComponent(this);
		}
	}

	void SetPlayerHidden(bool bStatus)
	{
		if(bHasPlayerVisibilityChangeActive == bStatus)
			return;

		bHasPlayerVisibilityChangeActive = bStatus;

		if(bStatus)
		{
			Player.SetActorHiddenInGame(true);
			Player.OtherPlayer.DisableOutlineByInstigator(this);
		}
		else
		{
			Player.SetActorHiddenInGame(false);
			Player.OtherPlayer.EnableOutlineByInstigator(this);
		}
	}

	bool CanExitPlant() const
	{
		if(CurrentPlant == nullptr)
			return false;

		return CurrentPlant.CanExitPlant();
	}

	UFUNCTION()
	private void FinishActivatingPlant()
	{
		CurrentPlant = PlantToActivate;
		//CurrentPlant.SetupPlayer();
		CurrentPlant.OnActivatePlant();
		CurrentPlant.bIsPlantActive = true;

		PlantToActivate = nullptr;
	}

	void StopEnterSoilAnimation()
	{
		if(Player.IsPlayingAnimAsSlotAnimation(EnterSoilAnim))
			Player.StopAnimationByAsset(EnterSoilAnim);
	}

	AControllablePlant FindInstanceFromClassType(TSubclassOf<AControllablePlant> InPlantClass)
	{
		for(AControllablePlant Plant : AvailablePlants)
		{
			if(Plant.IsA(InPlantClass))
				return Plant;
		}

		return nullptr;
	}

	void SetLinkedActivatingSoil(USubmersibleSoilComponent Soil) property
	{
		if(Soil != nullptr)
		{
			InternalLinkedActivatingSoil = Soil;
			LinkedSoilCounter++;
		}	
	}

	void ClearLinkedActiveSoil()
	{
		LinkedSoilCounter--;
		if(LinkedSoilCounter <= 0)
		{
			InternalLinkedActivatingSoil = nullptr;
		}
	}

	USubmersibleSoilComponent GetLinkedActivatingSoil() const property
	{
		return InternalLinkedActivatingSoil;
	}

	TSubclassOf<AControllablePlant> GetTargetPlantClass() const property { return _TargetPlantClass; }

	void SetTargetPlantClass(TSubclassOf<AControllablePlant> NewPlantClass) property
	{
		NetSetTargetPlantClass(NewPlantClass);
	}

	// Called from the plant to be played out on the player and it's own crumb trail.
	private FVector SyncLocation;
	private FRotator SyncRotation;
	private EControllablePlantExitBehavior SyncExitBehavior;

	void OnUnpossessPlant(FVector InLocation, FRotator InRotation, EControllablePlantExitBehavior ExitBehavior)
	{
		SyncLocation = InLocation;
		SyncRotation = InRotation;
		SyncExitBehavior = ExitBehavior;
		Sync::FullSyncPoint(this, n"SyncOnUnpossessPlant");
	}

	UFUNCTION(NotBlueprintCallable)
	private void SyncOnUnpossessPlant()
	{
		SetPlayerBlocks(false);
		SetPlayerHidden(false);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);

		if(CurrentPlant != nullptr)
		{
			if(SyncExitBehavior == EControllablePlantExitBehavior::PlantLocationGround)
			{
				FVector Start = CurrentPlant.ActorLocation + FVector::UpVector * 500;
				FVector End = Start - FVector::UpVector * 1500;
				FHitResult Hit;

				TArray<AActor> IgnoreActors;
				IgnoreActors.Add(CurrentPlant);
				IgnoreActors.Add(Game::GetCody());
				IgnoreActors.Add(Game::GetMay());

				System::LineTraceSingle(Start, End, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
				SyncLocation = Hit.ImpactPoint;
			}

			CurrentPlant.RemovePlayerSheet();
		}

		CurrentPlant = nullptr;

		Player.CleanupCurrentMovementTrail();
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		if(SyncExitBehavior == EControllablePlantExitBehavior::ExitSoil)
		{
			PlayExitSoilVFX(SyncLocation);
			PlayExitSoilAnimation();
			Player.TeleportActor(SyncLocation, SyncRotation);
		}
		else if(SyncExitBehavior == EControllablePlantExitBehavior::PlantLocation)
		{
			StopEnterSoilAnimation();
		}
		else if(SyncExitBehavior == EControllablePlantExitBehavior::PlantLocationGround)
		{
			PlayExitSoilVFX(SyncLocation);
			PlayExitSoilAnimation();
			Player.TeleportActor(SyncLocation, SyncRotation);
		}

		OnExitSoilComplete.Broadcast();

		if(ActivatingSoil != nullptr)
		{
			FPlayerSubmergedInSoilInfo EventParams;
			EventParams.Soil = ActivatingSoil;
			EventParams.BroadcastExit();
		}
	}

	UFUNCTION(NetFunction)
	private void NetSetTargetPlantClass(TSubclassOf<AControllablePlant> NewPlantClass)
	{
		if(!HasControl())
			return;

		if(CurrentPlant != nullptr && CurrentPlant.IsA(NewPlantClass))
			return;

		_TargetPlantClass = NewPlantClass;
	}

	void PlayEnterSoilAnimation() const
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = EnterSoilAnim;
		Params.bPauseAtEnd = true;
		Params.BlendTime = 0.f;
		Player.PlaySlotAnimation(Params);
	}

	void PlayExitSoilAnimation() const
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ExitSoilAnim;
		Params.BlendTime = 0.f;
		Params.BlendType = EHazeBlendType::BlendType_Crossfade;
		Player.PlaySlotAnimation(Params);
		if(CurrentPlant != nullptr)
			CurrentPlant.SetCapabilityActionState(n"Audio_OnExitSoil", EHazeActionState::ActiveForOneFrame);
	}

	void ClearTargetPlantClass()
	{
		_TargetPlantClass = nullptr;
	}

	// Called from anywhere, such as level blueprint, used to trigger DeactivatePlantCapability
	void DeactivatePlant()
	{
		NetDeactivatePlant();
	}

	UFUNCTION(NetFunction)
	private void NetDeactivatePlant()
	{
		if(!HasControl())
			return;

		if(CurrentPlant == nullptr)
			return;

		bDeactivatePlant = true;
	}

	void PlayExitSoilVFX(FVector Loc)
	{
		if(ExitSoilVFX != nullptr)
			Niagara::SpawnSystemAtLocation(ExitSoilVFX, Loc);
	}
}
