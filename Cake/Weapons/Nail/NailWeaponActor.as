import Vino.Pierceables.PiercingComponent;
import Vino.Pierceables.PierceStatics;
import Cake.Weapons.Nail.NailWeaponMeshComponent;
import Cake.Weapons.Nail.NailWeaponMovementComponent;
import Vino.ContextIcons.ContextIconWidget;

event void FNailRecalled(const float EstimatedTravelTime);
event void FNailRecallEnterCollsionEventSignature(const float TravelTimeRemaining, FHitResult HitData);
event void FNailRecallExitCollsionEventSignature(const float TravelTimeRemaining, FHitResult HitData);

event void FNailThrownEventSignature();
event void FNailCollsionEventSignature(FHitResult HitData);

event void FNailCaughtEventSignature();

event void FNailWiggleEventSignature();

event void FNailWeaponEquippedEventSignature(AHazePlayerCharacter Wielder);
event void FNailWeaponUnequippedEventSignature(AHazePlayerCharacter Wielder);

UCLASS(abstract)
class UNailRecallWidget : UHazeUserWidget
{
	UPROPERTY()
	float ProgressAlpha;

	UPROPERTY()
	EContextIconState State;

	UPROPERTY()
	FName ActionName = n"WeaponReload";

	// used to hide the widget when the nail pierces a surfaces and starts wiggling. 
	bool bHasLeftEnterWiggleZone = false;
};

UCLASS(abstract)
class ANailWeaponActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UNailWeaponMeshComponent Mesh;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UPROPERTY(DefaultComponent)
	UNailWeaponMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UNailRecallComponent RecallComponent;

	UPROPERTY(DefaultComponent)
	UPiercingComponent PiercingComponent;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ThrowEffect;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent RecallEffect;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent CatchEffect;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ThrowEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CatchEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RecallEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InComingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PassbyEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StickImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MaterialImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WiggleStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WiggleStopEvent;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailThrownEventSignature OnNailThrownEvent;

	// before it gets attached
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailCaughtEventSignature OnNailPreCaughtEvent;

	// after it gets attached
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailCaughtEventSignature OnNailPostCaughtEvent;

	// Local Only?
  	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailCollsionEventSignature OnNailCollision; 

	/* When the nail weapon is equipped on the character. (Also trigger on recalls) */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailWeaponEquippedEventSignature OnNailEquipped;
		
	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailWeaponUnequippedEventSignature OnNailUnequipped;

	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailRecalled OnNailRecalled;

	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailWiggleEventSignature OnNailWiggleStart;

	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailWiggleEventSignature OnNailWiggleEnd;

  	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailRecallEnterCollsionEventSignature OnNailRecallEnterCollision; 

  	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailRecallEnterCollsionEventSignature OnNailRecallExitCollision; 

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	UNailRecallWidget RecallWidget;

	TArray<FNailHitData> QueuedCrumbCollisionHits;
	// TArray<FHitResult> QueuedCrumbCollisionHits;
	bool bSweep = false;

	float ElapsedTimeBetweenPhysxCollisions = 0.f;

	protected AHazeActor WielderCurrent = nullptr;
	protected AHazeActor WielderPrevious = nullptr;

	UPROPERTY()
	FText RecallNailTutorialText;

	// Transients 
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	float GetTimeSinceLaunch() const
	{
		return Time::GetGameTimeSince(MovementComponent.TimeStampLaunched);
	}

	UFUNCTION(BlueprintPure)
	FVector GetNailVelocity() const
	{
		if(Mesh.IsSimulatingPhysics())
			return Mesh.GetPhysicsLinearVelocity();
		return MovementComponent.Velocity;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PiercingComponent.Pierced.AddUFunction(this, n"HandlePierced");
		PiercingComponent.Unpierced.AddUFunction(this, n"HandleUnpierced");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//////////////////////////////////////////////////////////////////////////
		// @TODO: ask Jonas or Oskar about this..
		// This tag was supposed to be requested all the time.. so we put it here.
		// otherwise they'll T.pose?
		if(Mesh.GetAnimationMode() == EAnimationMode::AnimationBlueprint)
		{
			FHazeRequestLocomotionData LocoRequest;
			LocoRequest.AnimationTag = n"Movement";
			Mesh.RequestLocomotion(LocoRequest);
		}
		//////////////////////////////////////////////////////////////////////////

		// PrintToScreen("Animationmode: " + Mesh.GetAnimationMode());
		// PrintToScreen("ASsignedIndex: " + Mesh.AssignedIndex);
	}

	void ReactToRagdollCollision()
	{
		ensure(QueuedCrumbCollisionHits.Num() == 1);
		const int32 FinalIdx = QueuedCrumbCollisionHits.Num() - 1;
		OnNailCollision.Broadcast(QueuedCrumbCollisionHits[FinalIdx].MakeHitResult());
		QueuedCrumbCollisionHits.RemoveAt(FinalIdx);
	}

	void HandlePiercingHit()
	{
		ensure(QueuedCrumbCollisionHits.Num() == 1);
		const int32 FinalIdx = QueuedCrumbCollisionHits.Num() - 1;
		StopSweeping();
		PiercingComponent.Pierce(QueuedCrumbCollisionHits[FinalIdx].MakeHitResult());
		QueuedCrumbCollisionHits.RemoveAt(FinalIdx);
	}

	void HandleNonPiercingHit()
	{
		ensure(QueuedCrumbCollisionHits.Num() == 1);
		const int32 FinalIdx = QueuedCrumbCollisionHits.Num() - 1;
		HandleCollision(QueuedCrumbCollisionHits[FinalIdx].MakeHitResult());
		QueuedCrumbCollisionHits.RemoveAt(FinalIdx);
	}

	// Audio & Effects wants to know when the ragdolling nail bounces 
	bool SweepForNailCollisionsWhileRagdolling(const float Dt, FHitResult& OutHit) 
	{
		if (bSweep)
			return false;

		if (!Mesh.IsSimulatingPhysics())
			return false;

		const FVector NailPhysVelocity = GetNailVelocity();
		if(NailPhysVelocity.IsZero())
			return false;

		TArray<FHitResult> Hits;
		if(Trace::SweepComponentForHits(Mesh, NailPhysVelocity.GetSafeNormal(), Hits, true))
		{
			if(ElapsedTimeBetweenPhysxCollisions > 0.f)
			{
				OutHit = Hits.Last();
				ElapsedTimeBetweenPhysxCollisions = 0.f;
				return true;
			}
			ElapsedTimeBetweenPhysxCollisions = 0.f;
		}
		else
		{
			ElapsedTimeBetweenPhysxCollisions += Dt;
		}

		return false;
	}

	void HandleCollision(const FHitResult& HitData)
	{
		// We've hit something and that wasn't a piercing hit 
		// so the custom data is no longer valid
		PiercingComponent.ResetCustomHitData();

		// I'm assuming DeltaMove won't be applied
		// so let's snap to the target location
		SetActorLocation(HitData.ImpactPoint);

		// Ragdoll
		Mesh.EnableAndApplyCachedPhysicsSettings();

		// we have to either enable it here. Or in the BP Or when we equip the weapon.
		Mesh.SetSimulatePhysics(true);

		// Collision response. Bounce velocity after the impact using coefficient of restitution.
		MovementComponent.AddCollisionBounce(HitData.ImpactNormal);
		Mesh.SetPhysicsLinearVelocity(MovementComponent.Velocity);

		// FVector LinearImpulse = HitData.ImpactNormal;
		// LinearImpulse *= MovementComponent.Velocity.Size();
		// LinearImpulse *= Mesh.GetMass();
		// LinearImpulse *= 0.2f;
		// Mesh.AddImpulse(LinearImpulse, NAME_None, false);

		FVector AngularImpulse = MovementComponent.Velocity.CrossProduct(FVector::UpVector);
		AngularImpulse *= -1.f;
		AngularImpulse *= MovementComponent.Restitution;
		Mesh.SetPhysicsAngularVelocityInDegrees(AngularImpulse);

		OnNailCollision.Broadcast(HitData);

		if (HitData.Actor != nullptr)
		{
			UPierceableComponent PierceableComp = UPierceableComponent::Get(HitData.Actor);
			if (PierceableComp != nullptr)
				PierceableComp.NonPiercingHit.Broadcast(HitData, this);
		}

		ElapsedTimeBetweenPhysxCollisions = 0.f;
		Mesh.SetAnimBoolParam(n"NailCollision", true);
		bSweep = false;
	}

	FVector GetThrowDirection(const FVector& PointToHit) const
	{
		const FVector WeaponLocation = GetActorLocation();
		FVector ThrowDirection = PointToHit - WeaponLocation;
		ThrowDirection.Normalize();
		return ThrowDirection;
	}

	UFUNCTION(NotBlueprintCallable)
	void HandlePierced(
		AActor ActorDoingThePiercing = nullptr,
		AActor ActorBeingPierced = nullptr,
		UPrimitiveComponent ComponentBeingPierced = nullptr,
		FHitResult HitResult = FHitResult()
	)
	{
		SetAnimBoolParam(n"NailPierced", true);
		if(ComponentBeingPierced.HasTag(ComponentTags::NailSwingable) == false)
			SetAnimBoolParam(n"NailSubmerged", true);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleUnpierced()
	{
		SetAnimBoolParam(n"NailUnpierced", true);
		SetAnimBoolParam(n"NailSubmerged", false);
	}

	UFUNCTION(NetFunction)
	void NetStopSweeping()
	{
		StopSweeping();
	}

	void StopSweeping()
	{
		bSweep = false;
		Mesh.DisableAndCachePhysicsSettings();
	}

	void LaunchNail(FNailTargetData InTargetData, const float ImpulseMagnitude)
	{
		if (GetWielder() != nullptr)
		{
			PrintWarning("LaunchNail() failed. Detach the nail before calling LaunchNail()");
			return;
		}

		MovementComponent.AddIgnoreActor(GetPreviousWielder());

		auto Rule = EDetachmentRule::KeepWorld;
		DetachFromActor(Rule,Rule,Rule);

		Mesh.DisableAndCachePhysicsSettings();

		const FVector ThrowDirection = InTargetData.Direction;
		const FVector ThrowImpulse = ThrowDirection * ImpulseMagnitude;

  		const FRotator NewRotation = Math::MakeRotFromZ(-ThrowDirection);
		SetActorRotation(NewRotation, true);

		// move the nail forwards to be parallel with the camera 
		// when the camera happens to be in front of the nail. 
		const FVector CurrentNailPos = GetActorLocation();
		const FVector NewNailPos = FMath::ClosestPointOnLine(
			CurrentNailPos,
			CurrentNailPos + ThrowImpulse,
			Game::GetCody().ViewLocation
		);

		// Only update location when camera is in front of nail
		if(CurrentNailPos != NewNailPos)
			SetActorLocation(NewNailPos);

		MovementComponent.InitHoming(InTargetData, ImpulseMagnitude);
		MovementComponent.ResetPhysics();

		MovementComponent.Velocity += ThrowImpulse;

		MovementComponent.TimeStampLaunched = Time::GetGameTimeSeconds();

		bSweep = true;
		OnNailThrownEvent.Broadcast();
	}

	/* returns the actor which is wielding the weapon. */
	UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
	AHazeActor GetWielder() const
	{
		return WielderCurrent;
	}

	/* returns the actor which previously wielded the weapon. (will return NULL unless the weapon has been Equipped twice.) */
	UFUNCTION(BlueprintPure, Category = "Weapon|Nail")
	AHazeActor GetPreviousWielder() const
	{
		return WielderPrevious;
	}

	void SetWielder(AHazeActor NewWielder)
	{
		if (NewWielder == WielderCurrent)
			return;

		WielderPrevious = GetWielder();
		WielderCurrent = NewWielder;
	}

};

/* Used to create a custom FHitResult */
struct FNailHitData
{
	UPROPERTY()
	bool bValid = false;

	UPROPERTY()
	UPrimitiveComponent ComponentThatGotHit = nullptr;

	UPROPERTY()
	FVector ImpactPointAsLocalOffset = FVector::ZeroVector;

	UPROPERTY()
	FVector ImpactNormal = FVector::ZeroVector;

	UPROPERTY()
	FName BoneName = NAME_None;

	bool IsValid() const
	{
		return bValid;
	}

	FHitResult MakeHitResult() const
	{
 		FHitResult HitDataCreated = FHitResult(
			ComponentThatGotHit.GetOwner(),
			ComponentThatGotHit,
			GetImpactPoint(),
			ImpactNormal
		);

		HitDataCreated.BoneName = BoneName;

		return HitDataCreated;

 		// return FHitResult(ComponentThatGotHit.GetOwner(), ComponentThatGotHit, GetImpactPoint(), ImpactNormal);
	}

	FVector GetImpactPoint() const
	{
		const FTransform HitComponentTransform = ComponentThatGotHit.GetWorldTransform();
		return HitComponentTransform.TransformPosition(ImpactPointAsLocalOffset);
	}

	void Invalidate() 
	{
		bValid = false;
		ComponentThatGotHit = nullptr;
		ImpactPointAsLocalOffset = FVector::ZeroVector;
		ImpactNormal = FVector::ZeroVector;
		BoneName = NAME_None;
	}

	FNailHitData() 
	{
		Invalidate();
	}

	FNailHitData(const FHitResult& InHitResult) 
	{
		bValid = true;
		ComponentThatGotHit = InHitResult.GetComponent();
		ImpactPointAsLocalOffset = InHitResult.GetComponent().GetWorldTransform().InverseTransformPosition(InHitResult.ImpactPoint);
		ImpactNormal = InHitResult.ImpactNormal;
		BoneName = InHitResult.BoneName;
	}

};

