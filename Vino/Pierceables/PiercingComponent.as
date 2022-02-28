
import Vino.Pierceables.PierceableComponent;
import Vino.Pierceables.PierceBaseComponent;

/**
 * Used to pierce make its owner pierce through objects and make it stick.
 * The piercing will only take place if the object being hit has a PierceableComponent
 */

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Tags Collision AssetUserData Activation")
class UPiercingComponent : UPierceBaseComponent
{
	private FHitResult CustomHitResult;
	private bool bSimulatePhysicsPreAttachment = false;

	FWiggleIntoPierce WiggleIntoPierce;

	void PushPiercingEvent(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent CompBeingPiercead, FHitResult HitResult)
	{
		Pierced.Broadcast(ActorDoingThePiercing, ActorBeingPierced, CompBeingPiercead, HitResult);
		PierceActors.AddUnique(ActorBeingPierced);
	}

	void PushUnpiercingEvent(AActor OtherActor = nullptr)
	{
		Unpierced.Broadcast();
		PierceActors.Reset();		// we should only be able to pierce 1 thing 

		// reset
		bSkipWiggleIntoPierce = false;
	}

	bool GetPiercingHitFromHits(const TArray<FHitResult>& Hits, FHitResult& OutData)
	{
		for (int i = Hits.Num() - 1; i >= 0 ; i--)
		{
			const FHitResult& Hit = Hits[i];

			UPrimitiveComponent HitComponent = Hit.GetComponent();
			if (!HitComponent.HasTag(ComponentTags::Piercable))
				continue;

			// only use the CustomHitResult if it's still valid. 
			// It might fail if the target we want to hit is moving
			// faster than the thing being thrown. 
			const bool bWantToUseCustomHitData = WantToUseCustomHitResult();
			const bool bCustomHitDataIsStillValid = IsCustomHitResultStillValid(HitComponent);
			if (bWantToUseCustomHitData && ensure(bCustomHitDataIsStillValid))
				OutData = CustomHitResult;
			else
				OutData = Hit;

			return true;
		}

		return false;
	}

	void Pierce(const FHitResult& HitData)
	{
		AActor ActorThatGotPierced = HitData.GetActor();
		UPrimitiveComponent ComponentThatGotPierced = HitData.GetComponent();
		AActor ActorDoingThePiercing = GetOwner();

		// save rotation as we will re-apply it after broadcasting events
		const FRotator RotationUponImpact = ActorDoingThePiercing.GetActorRotation();

		DisableAndSavePhysicsSettings();

 		FVector AttachmentLocation = HitData.ImpactPoint;

		UPierceableComponent PierceableComp = UPierceableComponent::Get(ActorThatGotPierced);
		if (PierceableComp != nullptr && PierceableComp.ExtraPiercingDepth != 0.f)
			AttachmentLocation -= (HitData.ImpactNormal * PierceableComp.ExtraPiercingDepth);

		// We want the nail to penetrate the wood deep enough in order to see the tip come out on the other side
		AttachmentLocation -= (HitData.ImpactNormal * 30.f);

		ActorDoingThePiercing.SetActorLocation(AttachmentLocation);

		// make sure that event listeners can read the final rotation from the nail by temporarily
		// applying the final rotation here before we broadcast the event. 
		const FRotator AttachmentRotation = Math::MakeRotFromZ(HitData.ImpactNormal);
		ActorDoingThePiercing.SetActorRotation(AttachmentRotation);

		// ActorDoingThePiercing.AttachToComponent(ComponentThatGotPierced, NAME_None, EAttachmentRule::KeepWorld);
		ActorDoingThePiercing.AttachToComponent(ComponentThatGotPierced, HitData.BoneName, EAttachmentRule::KeepWorld);

		// make the match look bigger once it is attached 
		ActorDoingThePiercing.SetActorScale3D(1.4f);

		// Handle events
		ActorThatGotPierced.OnDestroyed.AddUFunction(this, n"DetachFromPiercedTarget");
		PushPiercingEvent(ActorDoingThePiercing, ActorThatGotPierced, ComponentThatGotPierced, HitData);
		if (PierceableComp != nullptr)
			PierceableComp.PushPiercingEvent(ActorDoingThePiercing, ActorThatGotPierced, ComponentThatGotPierced, HitData);

		ResetCustomHitData();

		// the wiggle is allowed to be skipped because something wants the nail to stop moving when the events fire.
		// (Running the wiggle and canceling it immediately afterwards won't work due to the hit normal being relative to the attachParent)
		if (!bSkipWiggleIntoPierce)
		{
			// re-apply rotation after all events have fired and the let wiggle rotator
			// rotate the nail it the final rotation over time.
			ActorDoingThePiercing.SetActorRotation(RotationUponImpact);
			WiggleIntoPierce = FWiggleIntoPierce(ActorDoingThePiercing, HitData);
		}
	}

	bool bSkipWiggleIntoPierce = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// @TODO:  move this to a capability once we get animations from oskar
		if(WiggleIntoPierce.bEnabled)
			WiggleIntoPierce.UpdateWiggle(DeltaSeconds);
	}

	UFUNCTION(NotBlueprintCallable)
	void DetachFromPiercedTarget(AActor ActorToDetachFrom) 
	{
		PushUnpiercingEvent();
		const auto Rule = EDetachmentRule::KeepWorld;
		GetOwner().DetachFromActor(Rule, Rule, Rule);
		EnableAndApplyPhysicsSettings();
	}

	void EnableAndApplyPhysicsSettings() 
	{
		UPrimitiveComponent RootPrimitive = UPrimitiveComponent::Get(GetOwner());
		RootPrimitive.SetSimulatePhysics(bSimulatePhysicsPreAttachment);
	}

	void DisableAndSavePhysicsSettings() 
	{
		UPrimitiveComponent RootPrimitive = UPrimitiveComponent::Get(GetOwner());
		bSimulatePhysicsPreAttachment = RootPrimitive.IsSimulatingPhysics();
		RootPrimitive.SetSimulatePhysics(false);
	}

	bool IsCustomHitResultStillValid(UPrimitiveComponent HitComponent) const
	{
		return CustomHitResult.GetComponent() == HitComponent;
	}

	bool WantToUseCustomHitResult() const
	{
		return CustomHitResult.GetActor() != nullptr;
	}

	void SetCustomHitData(const FHitResult& InCustomHitData)
	{
		CustomHitResult = InCustomHitData;
	}

	void ResetCustomHitData() 
	{
		CustomHitResult.Reset();
	}

}

struct FWiggleIntoPierce
{
	float Time = 0.f;
	float Damping = 0.f;
	float Stiffness = 0.f;
	float TimeRemaining = 0.f;
	bool bFullySubmerged = false;
	FHazeAcceleratedRotator Rot;
	bool bEnabled = false;
	AActor PiercingActor;

	FVector LocalImpactNormal = FVector::ZeroVector;

	const float FixedDt = 1.f / 120.f;
	float TimeToProcess = 0.f;

	// We assume hit data doesn't change after Init()
	private FHitResult HitData;

	FRotator GetFinalRotation() const
	{
		if(HitData.Component == nullptr)
		{
			ensure(false);
			return FRotator::MakeFromZ(LocalImpactNormal);
		}

		// need to handle the case when the thing rotates while nail wiggles
		const FVector WorldImpactNormal = HitData.GetComponent().GetSocketQuaternion(HitData.BoneName).RotateVector(LocalImpactNormal); 

		return FRotator::MakeFromZ(WorldImpactNormal);
	}

	FWiggleIntoPierce(AActor InPiercingActor, const FHitResult& InHitData)
	{
		Init(InPiercingActor, InHitData);
	}

	void ForceFinishWiggle()
	{
		if(!bEnabled)
			return;

		PiercingActor.SetActorRotation(GetFinalRotation());
		bEnabled = false;
	}

	void Init (AActor InPiercingActor, const FHitResult& InHitData)
	{
		HitData = InHitData;

		LocalImpactNormal = HitData.GetComponent().GetSocketQuaternion(HitData.BoneName).UnrotateVector(HitData.ImpactNormal);

		PiercingActor = InPiercingActor;
		Rot.SnapTo(InPiercingActor.GetActorRotation());
		bEnabled = true;

		bFullySubmerged = !HitData.GetComponent().HasTag(ComponentTags::NailSwingable); 
		if(bFullySubmerged)
		{
			Damping = 0.2f;
			Stiffness = 4000.f;
			TimeRemaining = Time = 1.f;
			TimeToProcess = 0.f;
		}
		else 
		{
			Damping = 0.05f;
			Stiffness = 1000.f;
			TimeRemaining = Time = 1.f;
			TimeToProcess = 0.f;
		}

	}

	void UpdateWiggle(const float Dt)
	{
		TimeToProcess += Dt;
		while(TimeToProcess >= FixedDt)
		{
			Rot.SpringTo(
				GetFinalRotation(),
				Stiffness,
				Damping,
				FixedDt
				// Dt	
			);
			TimeToProcess -= FixedDt;
		}

		// Rot.SpringTo(
		// 	FinalRotation,
		// 	Stiffness,
		// 	Damping,
		// 	Dt	
		// );

		PiercingActor.SetActorRotation(Rot.Value);

//		System::DrawDebugCoordinateSystem(PiercingActor.GetActorLocation(), PiercingActor.GetActorRotation(), 100.f, 0.f, 4.f);

		TimeRemaining = FMath::Max(TimeRemaining - Dt, 0.f);
		if(TimeRemaining == 0.f)
		{
			// Print("Wiggle is done" , Duration = Time);
			PiercingActor.SetActorRotation(GetFinalRotation());
			bEnabled = false;
		}

	}
};

