import Vino.Movement.Components.MovementComponent;
import Vino.ActivationPoint.ActivationPointStatics;
import Rice.Debug.DebugStatics;
import Vino.Movement.Swinging.SwingSettings;
import Vino.Movement.Swinging.SwingRope;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.MovementSystemTags;

event void FOnSwingPointBeginOverlap(USwingPointComponent SwingPoint);
event void FOnSwingPointEndOverlap(USwingPointComponent SwingPoint);
event void FOnAttachedToSwingPoint(USwingPointComponent SwingPoint);
event void FOnDetachedFromSwingPoint(USwingPointComponent SwingPoint);

class USwingingComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false; // this component dont need to tick
	
	UPROPERTY(NotEditable)
	FVector CurrentDirection;
	UPROPERTY(NotEditable)
	FVector DesiredDirection;
	UPROPERTY(NotEditable)
	FVector TargetDesired;

	FVector InheritedVelocity;

	AHazePlayerCharacter PlayerOwner;
	FOnAttachedToSwingPoint OnAttachedToSwingPoint;
	FOnDetachedFromSwingPoint OnDetachedFromSwingPoint;

	UPROPERTY()
	USwingingEffectsDataAsset EffectsData;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset DefaultCameraSettings;

	UPROPERTY()
	UForceFeedbackEffect AttachForceFeedback;

	USwingPointComponent ActivatedPoint;
	USwingPointComponent PreviousSwingPoint;

	UPROPERTY()
	TSubclassOf<ASwingRope> SwingRopeClass;
	ASwingRope SwingRope;

	float SwingDuration = 0.f;
	bool bSwingingActive = false;

	private FName DefaultSwingAttachSocketName = n"RightAttach";
	private FName MatchWeaponSwingAttachSocketName = n"LeftAttach";
	FName SwingAttachSocketName = DefaultSwingAttachSocketName;

	UPROPERTY()
	UStaticMesh RopeKnotMesh;
	UPROPERTY(NotEditable)
	UStaticMeshComponent RopeKnot;

	void UseDefaultSwingAttachSocketName()
	{
		SwingAttachSocketName = DefaultSwingAttachSocketName;
	}

	void UseWeaponSwingAttachSocketName()
	{
		SwingAttachSocketName = MatchWeaponSwingAttachSocketName;
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		SwingRope = Cast<ASwingRope>(SpawnPersistentActor(SwingRopeClass, Owner.ActorLocation));

		if (SwingRope != nullptr)
			SwingRope.AttachToComponent(PlayerOwner.Mesh, n"RightAttach");
    }

	UFUNCTION(BlueprintOverride)
	void EndPLay(EEndPlayReason EndReason)
	{
		SwingRope.DestroyActor();
		SwingRope = nullptr;
	}

	UFUNCTION(BlueprintPure)
	FVector GetPlayerLocation() property
	{
		return PlayerOwner.CapsuleComponent.WorldLocation;
	}
	
	UFUNCTION(BlueprintPure)
	ASwingRope GetActiveSwingRope() property
	{
		return SwingRope;
	}

	UFUNCTION(BlueprintPure)
	bool IsSwinging() const
	{
		return  bSwingingActive;
	}

	UFUNCTION(BlueprintPure)
	USwingPointComponent GetActiveSwingPoint() const property
	{
  		return Cast<USwingPointComponent>(PlayerOwner.GetActivePoint());
	}

	UFUNCTION(BlueprintPure)
	USwingPointComponent GetTargetSwingPoint() const property
	{
  		return Cast<USwingPointComponent>(PlayerOwner.GetTargetPoint(USwingPointComponent::StaticClass()));
	}

	UFUNCTION(BlueprintPure)
	FVector GetPlayerToSwingPoint() property
	{	
		if (GetActiveSwingPoint() != nullptr)
			return GetActiveSwingPoint().WorldLocation - PlayerLocation;

		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetDesiredMeshRotation() property
	{			
		return Math::MakeRotFromZX(GetPlayerToSwingPoint(), PlayerOwner.ActorForwardVector);
	}

	void UpdateSwingTime(float DeltaTime)
	{
		SwingDuration += DeltaTime;
	}

	float GetSwingAnglePercentage()
	{
		if (ActiveSwingPoint == nullptr)
			return 0.f;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::GetOrCreate(PlayerOwner);

		float SwingAngle = PlayerToSwingPoint.AngularDistance(MoveComp.WorldUp) * RAD_TO_DEG;
		return FMath::Min(SwingAngle / ActiveSwingPoint.SwingAngle, 1.f);
	}

	void StartSwinging(USwingPointComponent SwingPoint)
	{

		PlayerOwner.BlockCapabilities(n"Swimming", this);
		PlayerOwner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::WallSlide, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::GroundPound, this);

		PlayerOwner.ActivatePoint(SwingPoint, this);
		ActivatedPoint = SwingPoint;
		bSwingingActive = true;

		SwingDuration = 0.f;
	}

	void StopSwinging()
	{
		bSwingingActive = false;

		PlayerOwner.UnblockCapabilities(n"Swimming", this);

		PlayerOwner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::GroundPound, this);

		if (ActivatedPoint != nullptr)
		{
			ActivatedPoint.PlayerDetachTime[PlayerOwner] = System::GetGameTimeInSeconds();
			PreviousSwingPoint = ActivatedPoint;
			
			ActivatedPoint.OnSwingPointDetached.Broadcast(PlayerOwner);
			OnDetachedFromSwingPoint.Broadcast(ActivatedPoint);
			ActivatedPoint = nullptr;
		}

		PlayerOwner.DeactivateCurrentPoint(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		bSwingingActive = false;

		if (GetActiveSwingRope() != nullptr)
			GetActiveSwingRope().DetachFromSwingPoint();
	}

	void ShowRopeKnot()
	{
		if (!ActiveSwingPoint.bShowRopeKnotMesh)
			return;

		if (RopeKnotMesh != nullptr)
		{
			if (RopeKnot == nullptr)
			{
				RopeKnot = UStaticMeshComponent::Create(Owner, n"SwingingRopeKnot");
				RopeKnot.SetStaticMesh(RopeKnotMesh);
			}
			else
			{
				RopeKnot.SetHiddenInGame(false);
			}			
			RopeKnot.AttachToComponent(ActiveSwingPoint);

			UpdateRopeKnotTransform();
		}		
	}

	void HideRopeKnot()
	{
		if (RopeKnot != nullptr)
		{
			RopeKnot.SetHiddenInGame(true);
			RopeKnot.AttachToComponent(Owner.RootComponent);
		}
	}

	void UpdateRopeKnotTransform()
	{
		if (RopeKnot != nullptr)
		{
			FVector Forward = -PlayerToSwingPoint;
			FVector Right = -Owner.ActorRightVector;
			RopeKnot.WorldRotation = FRotator::MakeFromXY(Forward, Right);
		}
	}
}

class USwingingEffectsDataAsset : UDataAsset
{
	UPROPERTY(Category = Audio)
	UAkAudioEvent PlayerAttach;

	UPROPERTY(Category = Audio)
	UAkAudioEvent SwingPointAttach;

	UPROPERTY(Category = Audio)
	UAkAudioEvent PlayerDetach;

	UPROPERTY(Category = Audio)
	UAkAudioEvent SwingPointDetach;

	UPROPERTY(Category = Audio)
	UAkAudioEvent DirectionChange;
}
