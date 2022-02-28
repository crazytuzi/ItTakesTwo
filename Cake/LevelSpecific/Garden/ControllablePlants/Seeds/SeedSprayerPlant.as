import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;



class USeedSprayerPlantMovementComponent : UHazeBaseMovementComponent
{
	ASeedSprayerPlant PlantOwner;
	FVector LastValidLocation;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		UseCollisionSolver(n"DefaultCharacterCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");
		UseMoveWithCollisionSolver(n"DefaultCharacterMoveWithCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");
		PlantOwner = Cast<ASeedSprayerPlant>(Owner);
	}

	UFUNCTION(BlueprintOverride)
    void OnPreImpactsUpdated(FMovementCollisionData NewImpacts)
    {
        const FMovementCollisionData CurrentImpacts = GetPreviousImpacts();
        if (NewImpacts.UpImpact.Component != CurrentImpacts.UpImpact.Component)
        {
            CheckAndCallImpactCallback(CurrentImpacts.UpImpact, NewImpacts.UpImpact, EImpactDirection::UpImpact);
        }
        
        if (NewImpacts.ForwardImpact.Component != CurrentImpacts.ForwardImpact.Component)
        {
            CheckAndCallImpactCallback(CurrentImpacts.ForwardImpact, NewImpacts.ForwardImpact, EImpactDirection::ForwardImpact);
        }

        if (NewImpacts.DownImpact.Component != CurrentImpacts.DownImpact.Component)
        {
            CheckAndCallImpactCallback(CurrentImpacts.DownImpact,NewImpacts.DownImpact, EImpactDirection::DownImpact);
        }
    }

	// How much rotation difference this is between this and previous frame. -- Need to be called after the characers has moved to get correct values.
	float GetRotationDelta() const
	{
		return Math::DotToRadians(PreviousOwnerRotation.ForwardVector.DotProduct(OwnerRotation.ForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void PreMove()
	{
		LastValidLocation = PlantOwner.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void PostMove()
	{
		auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Game::GetCody());
		auto Soil = ColorContainerComponent.ActiveSoil; 
		if(Soil == nullptr || !Soil.SoilIsActive())
		{
			const FVector PlayerLocation = PlantOwner.GetActorLocation();
			const float Radius = ColorContainerComponent.ColorSystem.GetCpuDataSize().Size();
			const float CollisionRadius = PlantOwner.CollisionComp.GetCapsuleRadius();
			if(!ColorContainerComponent.ColorSystem.AreaHasBeenWatered(PlayerLocation, FMath::Max(Radius, CollisionRadius), 0.5f))
			{
				PlantOwner.SetActorLocation(LastValidLocation);
			}
		}
	}

    void CheckAndCallImpactCallback(const FHitResult& PreviousHit, const FHitResult& NewHit, EImpactDirection Direction)
    {
        // Call the previous Hits Callbacks
        if (PreviousHit.Component != nullptr)
        {
            if (PreviousHit.Actor != nullptr)
            {
                UActorImpactedCallbackComponent CallbackComponent = Cast<UActorImpactedCallbackComponent>(PreviousHit.Actor.GetComponentByClass(UActorImpactedCallbackComponent::StaticClass()));
                if (CallbackComponent != nullptr)
                {
                    CallbackComponent.ActorImpactEnded(HazeOwner, Direction);
                }
            }
        }

        // Call new hit Callbacks
        if (NewHit.Component == nullptr)
            return;

        if (NewHit.Actor == nullptr)
            return;

        UActorImpactedCallbackComponent CallbackComponent = Cast<UActorImpactedCallbackComponent>(NewHit.Actor.GetComponentByClass(UActorImpactedCallbackComponent::StaticClass()));
        if (CallbackComponent != nullptr)
        {
            CallbackComponent.ActorImpacted(HazeOwner, NewHit, Direction);
        }
    }

	 bool LineTraceGround(FVector Location, FHitResult& OutHit, float DistanceToTrace = 100.f, float DebugDraw = -1)
    {
        const FVector TraceTo = Location + -WorldUp * DistanceToTrace;
		FHazeHitResult Hit;
        LineTrace(Location, TraceTo, Hit, DebugDraw);
		OutHit = Hit.FHitResult;
		return OutHit.bBlockingHit;
    }

	UFUNCTION(BlueprintOverride)
	float GetWalkableAngle() const
	{
		return 55.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetCeilingAngle() const
	{
		return 30.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetMoveSpeed() const
	{
		return 850.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetRotationSpeed() const
	{
		return 0.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetMaxFallSpeed() const
	{
		return 1800.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetStepAmount(float WantedAmount) const
	{
		return WantedAmount < 0.f ? 40.f : WantedAmount;
	}

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const
	{
		return -3.f;
	}
}

UCLASS(Abstract)
class ASeedSprayerPlant : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.CapsuleHalfHeight = 88.f;
	default CollisionComp.CapsuleRadius = 30.f;
	default CollisionComp.SetCollisionProfileName(n"PlayerCharacterAffectedByCustomBlocker");
	default CollisionComp.RelativeLocation = FVector(0.f, 0.f, CollisionComp.CapsuleHalfHeight);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeOffsetComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	USeedSprayerPlantMovementComponent MovementComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = false;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem MoveUndergroundLoopEffectWhite;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem MoveUndergroundLoopEffectBlue;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem MoveUndergroundLoopEffectRed;

	//UPROPERTY(EditDefaultsOnly)
	//UNiagaraSystem SpawnEffect;

	// Called when the player deactivates the seedsprayer
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DeactivateEffect;

	// Called when the soil is fully planted
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FullyPlantedDeactivateEffect;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY(NotEditable)
	UNiagaraComponent MovingEffect;

	float CurrentSize = 0;
	float OriginalSize = 1.f;

	UPROPERTY(Category = Tutorial)
	FText RedText;

	UPROPERTY(Category = Tutorial)
	FText BlueText;

	default ExitTime = 0.4f;

	bool bIsExiting = false;
	bool bIsDisabled = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementComp.Setup(CollisionComp);
			
		AddCapability(n"SeedSprayerPlantMovementCapability");

		//DisableActor(Game::GetCody());
		OriginalSize = Mesh.GetWorldScale().Size();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Increase the size when activated to original size
		const float GrowSpeed = 1.f;
		CurrentSize = FMath::Min(CurrentSize + (DeltaTime * GrowSpeed), 1.f);
		Mesh.SetWorldScale3D(FVector(FMath::EaseOut(0.f, OriginalSize, CurrentSize, 2.f)));
	}

	bool CanMove() const
	{
		return CurrentSize >= 1.f;
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		AddPlayerSheet();
	}

	void OnActivatePlant() override
	{
		auto Cody = Game::GetCody();
		CollisionComp.CapsuleHalfHeight = Cody.CapsuleComponent.CapsuleHalfHeight;
		CollisionComp.CapsuleRadius = Cody.CapsuleComponent.CapsuleRadius;
		SetActorLocation(Cody.GetActorLocation());
		MeshOffset.SetRelativeLocation(FVector(0.f, 0.f, -3000.f));
		MeshOffset.ResetLocationWithTime(0.1f);

		if(bIsDisabled)
		{
			bIsDisabled = false;
			EnableActor(Cody);
		}

		//if(SpawnEffect != nullptr)
		//	Niagara::SpawnSystemAtLocation(SpawnEffect, GetActorCenterLocation());

		CurrentSize = 0;
		Mesh.SetWorldScale3D(FVector(CurrentSize));
		SkelMesh.ResetAllAnimation();

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;
		Cody.ApplyCameraSettings(
			CamSettings,
			BlendSettings,
			this,
			EHazeCameraPriority::Script
		);

		SetCapabilityActionState(n"AudioOnBecomeSeedSprayer", EHazeActionState::ActiveForOneFrame);
	}

	void PreDeactivate() override
	{
		SetAnimBoolParam(n"PlayExit", true);
	}

	void OnDeactivatePlant() override
	{
		auto Cody = Game::GetCody();
	
		 //if(DeactivateEffect != nullptr)
		// 	Niagara::SpawnSystemAtLocation(DeactivateEffect, GetActorCenterLocation());

		bIsDisabled = true;
		DisableActor(Cody);

		CurrentSize = 0;
		Cody.ClearCameraSettingsByInstigator(this, 1.0f);
		//Cody.Mesh.ResetAllAnimation();
		OnUnpossessPlant(ActorLocation, ActorRotation, EControllablePlantExitBehavior::PlantLocationGround);
	}
}
