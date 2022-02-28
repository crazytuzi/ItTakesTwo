import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Cake.Environment.BreakableComponent;

event void FGroundPoundedThroughActorEvent(AHazePlayerCharacter PlayerGroundPoundingActor);
delegate void FGroundPoundedThroughDelegate(AHazePlayerCharacter Player);

UFUNCTION()
void BindOnActorGroundPoundedThrough(AActor Actor, FGroundPoundedThroughDelegate Delegate)
{
	if (!devEnsure(Actor != nullptr, "Trying to bind BindOnActorGroundPoundedThrough on nullptr actor"))
		return;

    UGroundPoundThroughComponent GroundPoundComp = UGroundPoundThroughComponent::Get(Actor);
	if (!devEnsure(GroundPoundComp != nullptr, Actor.Name + ": Trying to bind BindOnActorGroundPoundedThrough on actor that doesn't have a GroundPoundThroughComponent"))
		return;

	GroundPoundComp.OnActorGroundPoundedThrough.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

class UGroundPoundThroughComponent : UActorComponent
{
	UPROPERTY()
	bool bTriggerBreakables = true;

	FGroundPoundedThroughActorEvent OnActorGroundPoundedThrough;

	UPROPERTY()
	float ScatterForce = 0.5f;

	UPROPERTY()
	float DirectionalMultiplier = 1.f;

	bool bIsEnabled = true;

	UFUNCTION()
	void DisablePoundThrough()
	{
		bIsEnabled = false;
	}

	UFUNCTION()
	void EnablePoundThrough()
	{
		bIsEnabled = true;
	}

	UFUNCTION()
	bool CanPoundThrough() const
	{
		if (!bIsEnabled)
			return false;

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner != nullptr && HazeOwner.IsActorDisabled(nullptr))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(UCharacterGroundPoundPassThroughCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(UCharacterGroundPoundPassThroughCapability::StaticClass());
	}

	void OnHit(AHazePlayerCharacter GroundPoundPlayer)
	{
		OnActorGroundPoundedThrough.Broadcast(GroundPoundPlayer);
	}
}

class UCharacterGroundPoundPassThroughCapability : UHazeCapability
{
	default RespondToEvent(GroundPoundEventActivation::System);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 16;

	UCharacterGroundPoundComponent GroundPoundComp;
	UHazeMovementComponent MoveComp;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling)
			&& !GroundPoundComp.IsCurrentState(EGroundPoundState::Starting))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling)
			&& !GroundPoundComp.IsCurrentState(EGroundPoundState::Starting))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams Params)
	{
		if (Notification != n"GroundPoundThroughCompHit")
			return;

		UGroundPoundThroughComponent ThroughComp = Cast<UGroundPoundThroughComponent>(Params.GetObject(n"GPTroughComp"));
		MoveComp.StartIgnoringActor(ThroughComp.Owner);

		if (ThroughComp.bTriggerBreakables)
		{
			FBreakableHitData HitData;
			HitData.HitLocation = Params.GetVector(n"GPImpactPoint");
			HitData.DirectionalForce = -MoveComp.WorldUp * ThroughComp.DirectionalMultiplier;
			HitData.ScatterForce = ThroughComp.ScatterForce;

			TArray<UActorComponent> Breakables;
			ThroughComp.Owner.GetAllComponents(UBreakableComponent::StaticClass(), Breakables);
			for (UActorComponent Breakable : Breakables)
			{
				UBreakableComponent Comp = Cast<UBreakableComponent>(Breakable);
				Comp.Break(HitData);
			}
		}

		ThroughComp.OnHit(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		//trace for what we are going to hit.
		float Speed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, GroundPoundSettings::Falling.FallTimeToReachMaxSpeed), FVector2D(GroundPoundSettings::Falling.FallStartSpeed, GroundPoundSettings::Falling.FallMaxSpeed), GroundPoundComp.FallTime);

		// Calculate delta location and move the character
		FVector DeltaToTrace = MoveComp.WorldUp * (-Speed * DeltaTime);
		DeltaToTrace -= MoveComp.WorldUp * (10.f + MoveComp.GetStepAmount(-1.f));
		FHazeTraceParams PoundTrace;
		PoundTrace.InitWithMovementComponent(MoveComp);
		PoundTrace.From = MoveComp.OwnerLocation;
		PoundTrace.To = PoundTrace.From + DeltaToTrace;
		PoundTrace.DebugDrawTime = IsDebugActive() ? 0.f : -1.f;

		FHazeHitResult Hit;
		if (!(PoundTrace.Trace(Hit) && Hit.Actor != nullptr))
			return;
		
		UGroundPoundThroughComponent ThroughComp = Cast<UGroundPoundThroughComponent>(Hit.Actor.GetComponentByClass(UGroundPoundThroughComponent::StaticClass()));
		if (ThroughComp == nullptr)
			return;
		
		if (!ThroughComp.CanPoundThrough())
			return;

		FCapabilityNotificationSendParams HitParams;
		HitParams.AddVector(n"GPImpactPoint", Hit.ImpactPoint);
		HitParams.AddObject(n"GPTroughComp", ThroughComp);
		TriggerNotification(n"GroundPoundThroughCompHit", HitParams);
	}
}
