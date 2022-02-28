import Cake.Weapons.Sap.SapWeaponSettings;
import Cake.Weapons.Sap.SapWeaponAimStatics;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Sap.SapCustomAttachComponent;
import Cake.Weapons.Sap.SapLog;
import Cake.Weapons.Match.MatchHitResponseComponent;

import bool SapCanExplodeThisFrame() from 'Cake.Weapons.Sap.SapManager';
import void SapTriggerExplosionAtPoint(FVector Location, float Radius) from 'Cake.Weapons.Sap.SapManager';
import void ExplodeSap(ASapBatch Batch) from 'Cake.Weapons.Sap.SapManager';

class USapBatchEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	ASapBatch Owner;

	void InitInternal(ASapBatch Batch)
	{
		SetWorldContext(Batch);
		Owner = Batch;
		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEnabled(FSapAttachTarget Where) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDisabled() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMassGained(float MassGained) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMassLost(float MassLost) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnIgnite(float ExplodeDelay) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLightFadeUp() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLightFadeDown() {}
}

class ASapBatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchHitComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;

	// Index of this batch in the manager list
	int Index = -1;
	bool bIsEnabled = false;

	// Attach target
	FSapAttachTarget Target;
	USapResponseComponent ResponseComp;
	USapCustomAttachComponent CustomAttach;

	// Exploding
	bool bIsIgnited = false;
	float ExplodeTimer = 0.f;
	bool bWantsToExplode = false;
	bool bHasExploded = false;

	// Mass degrading
	float MassPauseTimer;

	// Used to reset the auto aim angle if it was overriden
	float OriginalAutoAimAngle;

	// Used for recycling
	float EnableTime = 0.f;

	UPROPERTY(BlueprintReadOnly)
	float Mass = 0.f;

	// Saps can be hidden for multiple reasons, so track that here
	TSet<FName> HiddenNames;

	// Effect handling
	UPROPERTY(Category = "Events")
	TArray<TSubclassOf<USapBatchEventHandler>> EventHandlerClasses;
	TArray<USapBatchEventHandler> EventHandlers;

	void CallOnEnabledEvent(FSapAttachTarget Where)
	{
		for(auto Handler : EventHandlers)
			Handler.OnEnabled(Where);
	}
	void CallOnDisabledEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnDisabled();
	}
	void CallOnMassGainedEvent(float MassGained)
	{
		for(auto Handler : EventHandlers)
			Handler.OnMassGained(MassGained);
	}
	void CallOnMassLostEvent(float MassLost)
	{
		for(auto Handler : EventHandlers)
			Handler.OnMassLost(MassLost);
	}
	void CallOnExplodeEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnExplode();
	}
	void CallOnIgniteEvent(float ExplodeDelay)
	{
		for(auto Handler : EventHandlers)
			Handler.OnIgnite(ExplodeDelay);
	}
	void CallOnLightFadeUp()
	{
		for(auto Handler : EventHandlers)
			Handler.OnLightFadeUp();
	}
	void CallOnLightFadeDown()
	{
		for(auto Handler : EventHandlers)
			Handler.OnLightFadeDown();
	}

	void Init(int BatchIndex)
	{
		MatchHitComp.OnStickyHit.AddUFunction(this, n"HandleMatchHit");

		Index = BatchIndex;

		DisableActor(this);

		// Spawn up the event handlers!
		for(auto HandlerClass : EventHandlerClasses)
		{
			auto Handler = Cast<USapBatchEventHandler>(NewObject(this, HandlerClass));
			EventHandlers.Add(Handler);

			Handler.InitInternal(this);
		}

		OriginalAutoAimAngle = AutoAimTarget.AutoAimMaxAngle;
	}

	void EnableBatch(FSapAttachTarget Where, float InMass)
	{
		SapLog("SAP [" + Index + "\t] EnableBatch()");

		if (!ensure(!bIsEnabled))
			return;

		// Reset all stats
		Mass = InMass;
		MassPauseTimer = Sap::Batch::MassLossPause;
		Target = Where;
		bIsIgnited = false;
		ExplodeTimer = 0.f;
		bWantsToExplode = false;
		bHasExploded = false;

		// Attach!
		ensure(Where.Component != nullptr);
		AttachToComponent(Where.Component, Where.Socket);

		RootComponent.RelativeLocation = Where.RelativeLocation;
		RootComponent.RelativeRotation = Math::MakeRotFromZ(Where.RelativeNormal);
		RootComponent.WorldScale3D = GetBatchSize();

		// If this is a custom attach point, we want to inherit its scale!
		CustomAttach = Cast<USapCustomAttachComponent>(Where.Component);
		if (CustomAttach != nullptr)
		{
			// We have to be aligned, or scale will be weird :haahaa:
			RootComponent.RelativeRotation = FRotator();

			if (CustomAttach.bSapHidden)
				HideBatch(n"CustomHidden");
		}

		// Enable
		EnableActor(this);
		bIsEnabled = true;

		// Check if the thing we're attaching to is a sap response actor
		AutoAimTarget.bIsAutoAimEnabled = false;

		ResponseComp = (Target.Actor == nullptr) ? nullptr : USapResponseComponent::Get(Target.Actor);
		if (ResponseComp != nullptr)
		{
			// Only auto aim on sap response stuff!
			AutoAimTarget.bIsAutoAimEnabled = ResponseComp.bEnableSapAutoAim;

			if (ResponseComp.bOverrideSapAutoAimAngle)
				AutoAimTarget.AutoAimMaxAngle = ResponseComp.SapAutoAimAngle;
			else
				AutoAimTarget.AutoAimMaxAngle = OriginalAutoAimAngle;

			ResponseComp.OnMassAdded.Broadcast(Target, Mass);
		}

		CallOnEnabledEvent(Where);
		EnableTime = Time::RealTimeSeconds;

		// Set the actor scale, to avoid popping for one frame in case this happens before tick
		SetActorScale3D(FVector(GetBatchSize()));

		// Special stuff for swarm!
		// Set attached sap index for later lookup when the swarm dies
		auto SwarmMesh = Cast<USwarmSkeletalMeshComponent>(Target.Component);
		if (SwarmMesh != nullptr) 
		{
			int BoneIndex = SwarmMesh.GetParticleIndexByName(Target.Socket);
			ensure(BoneIndex != -1);
			ensure(SwarmMesh.Particles[BoneIndex].AttachedSapId == -1);

			SwarmMesh.Particles[BoneIndex].AttachedSapId = Index;
		}

		SetActorTickEnabled(false);
	}

	void DisableBatch()
	{
		SapLog("SAP [" + Index + "\t] DisableBatch()");

		if (!ensure(bIsEnabled))
			return;

		DisableActor(this);
		bIsEnabled = false;

		if (ResponseComp != nullptr)
			ResponseComp.OnMassRemoved.Broadcast(Target, Mass);
		ResponseComp = nullptr;

		// If this is a custom attach point, show again if we were previously hidden
		if (HiddenNames.Contains(n"CustomHidden"))
			ShowBatch(n"CustomHidden");

		AutoAimTarget.bIsAutoAimEnabled = false;

		CallOnDisabledEvent();

		// Special stuff for swarm!
		// If we disabled early for some reason (explosions maybe)
		// Tell the swarm particle it doesn't have an attached sap anymore
		auto SwarmMesh = Cast<USwarmSkeletalMeshComponent>(Target.Component);
		if (SwarmMesh != nullptr) 
		{
			int BoneIndex = SwarmMesh.GetParticleIndexByName(Target.Socket);
			ensure(BoneIndex != -1);
			ensure(SwarmMesh.Particles[BoneIndex].AttachedSapId == Index);

			SwarmMesh.Particles[BoneIndex].AttachedSapId = -1;
			SapLog("SAP [" + Index + "\t] Reset Swarm Bone [" + BoneIndex + "\t]");
		}

		DetachFromActor();
	}

	void FadeUpLight()
	{
		CallOnLightFadeUp();

		auto Light = ULightComponent::Get(this);
		Light.MarkRenderStateDirty();
	}

	void FadeDownLight()
	{
		CallOnLightFadeDown();

		auto Light = ULightComponent::Get(this);
		Light.MarkRenderStateDirty();
	}

	void ShowBatch(FName Tag)
	{
		if (!HiddenNames.Contains(Tag))
			return;

		HiddenNames.Remove(Tag);
		if (HiddenNames.Num() == 0)
			SetActorHiddenInGame(false);
	}

	void HideBatch(FName Tag)
	{
		if (HiddenNames.Contains(Tag))
			return;

		HiddenNames.Add(Tag);
		SetActorHiddenInGame(true);
	}

	float GainMass(float MassAmount)
	{
		if (bIsIgnited || bWantsToExplode)
			return 0.f;

		float MassDelta = FMath::Min(MassAmount, Sap::Batch::MaxMass - Mass);
		Mass += MassDelta;

		if (ResponseComp != nullptr && !FMath::IsNearlyZero(MassDelta))
			ResponseComp.OnMassAdded.Broadcast(Target, MassDelta);

		if (CustomAttach == nullptr)
			RootComponent.WorldScale3D = GetBatchSize();
		else
			RootComponent.WorldScale3D = CustomAttach.RelativeScale3D * GetBatchSize();

		CallOnMassGainedEvent(MassDelta);
		return MassDelta;
	}

	// Returns amount of mass that was removed
	float RemoveMass(float MassAmount)
	{
		if (bIsIgnited || bWantsToExplode)
			return 0.f;

		float MassDelta = FMath::Min(MassAmount, Mass);
		Mass -= MassDelta;

		if (ResponseComp != nullptr && !FMath::IsNearlyZero(MassDelta))
			ResponseComp.OnMassRemoved.Broadcast(Target, MassDelta);

		if (CustomAttach == nullptr)
			RootComponent.WorldScale3D = GetBatchSize();
		else
			RootComponent.WorldScale3D = CustomAttach.RelativeScale3D * GetBatchSize();

		CallOnMassLostEvent(MassDelta);
		return MassDelta;
	}

	float SetNewMass(float MassAmount)
	{
		float MassDelta = FMath::Clamp(MassAmount, 0.f, Sap::Batch::MaxMass) - Mass;
		if (FMath::IsNearlyZero(MassDelta))
			return 0.f;

		if (MassDelta > 0.f)
			return GainMass(MassDelta);
		else
			return RemoveMass(-MassDelta);
	}

	// Get the visual scale of this batch, as opposed to its mass
	UFUNCTION(BlueprintPure)
	float GetBatchSize()
	{
		// Area of sphere:
		// A = 4 * pi * radius^2
		// radius = sqrt(A / (4 * pi))
		
		// However! We want 1 mass to equal 1 radius
		// Se we just scale the mass by 4*pi
		return FMath::Sqrt(Mass);
	}

	UFUNCTION()
	void HandleMatchHit(AActor Match, UPrimitiveComponent HitComponent, FHitResult Hit)
	{
		ExplodeSap(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsIgnited)
		{
			ExplodeTimer -= DeltaTime;
			if (ExplodeTimer < 0.f)
			{
				RequestExplosion();
			}
		}

		// We were either directly told to explode, or the ignition-timer ran out
		if (bWantsToExplode && SapCanExplodeThisFrame())
		{
			PerformExplosion();
			bIsIgnited = false;
		}
	}

	void Ignite(float Delay)
	{
		if (bHasExploded)
			return;

		SapLog("SAP [" + Index + "\t] Ignite(" + Delay + ")");

		if (bIsIgnited)
			ExplodeTimer = FMath::Min(Delay, ExplodeTimer);
		else
			ExplodeTimer = Delay;

		if (!bIsIgnited)
			CallOnIgniteEvent(ExplodeTimer);
		bIsIgnited = true;

		SetActorTickEnabled(true);
	}

	void RequestExplosion()
	{
		SapLog("SAP [" + Index + "\t] RequestExplosion()");

		bWantsToExplode = true;
		SetActorTickEnabled(true);
	}

	void PerformExplosion()
	{
		SapLog("SAP [" + Index + "\t] PerformExplosion()");

		if (bHasExploded)
			return;

		bHasExploded = true;

		if (ResponseComp != nullptr)
			ResponseComp.OnSapExploded.Broadcast(Target, Mass);

		float MassPercent = Math::GetPercentageBetween(Sap::Batch::MinMass, Sap::Batch::MaxMass, Mass);

		// Special stuff for swarms 
		auto Swarm = Cast<ASwarmActor>(Target.Actor);
		if (Swarm != nullptr) 
			Swarm.HandleSapExplosion(Target.Component, Target.Socket, Target.RelativeLocation, MassPercent);

		float ExplodeRadius = FMath::Lerp(Sap::Explode::MinRadius, Sap::Explode::MaxRadius, MassPercent);

		// Check for proximity response components
		TArray<EObjectTypeQuery> ObjTypes;
		ObjTypes.Add(EObjectTypeQuery::WorldDynamic);
		ObjTypes.Add(EObjectTypeQuery::WorldStatic);
		ObjTypes.Add(EObjectTypeQuery::Pawn);
		TArray<AActor> IgnoreActors;
		TArray<AActor> OverlappedActors;

		System::SphereOverlapActors(Target.WorldLocation, ExplodeRadius, ObjTypes, AActor::StaticClass(), IgnoreActors, OverlappedActors);
		for(auto Actor : OverlappedActors)
		{
			auto ProxResponseComp = USapResponseComponent::Get(Actor);
			if (ProxResponseComp == nullptr || ProxResponseComp == ResponseComp)
				continue;

			ProxResponseComp.CallOnExplodeProximity(Target, Mass, Target.WorldLocation.Distance(Actor.ActorLocation));
		}

		// Continue spreading...
		SapTriggerExplosionAtPoint(Target.WorldLocation, ExplodeRadius);

		CallOnExplodeEvent();

		// If we're still enabled at this point (something might disable us in the time it takes to get here)
		if (bIsEnabled)
			DisableBatch();
	}
}