import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceConductor;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceConductorIndicatorStar;

event void FOnConductorChainConnected();
event void FOnConductorChainDisconnected();

UCLASS(Abstract)
class ASpaceConductorStartPoint : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElectricityOrigin;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;

	UPROPERTY(NotVisible)
	TArray<ASpaceConductor> AllConductors;
	UPROPERTY(NotEditable)
	TArray<ASpaceConductor> ActiveConductors;
	ASpaceConductor LastConductor;

	UPROPERTY()
	TArray<ASpaceConductorIndicatorStar> IndicatorStars;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLoopingConductorEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLoopingConductorEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ConnectToConductorEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DisconnectToConductorEvent;

	UPROPERTY(Category = "Audio Events")
	float ConductorCooldownTime = 0.f;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent HazeAkComp;

	int LastNumberOfActiveConducts = 0;
	bool bIsPlayingLoopingEvent = false;

	UPROPERTY()
	AActor EndPoint;

	TArray<AActor> ActorsToIgnore;

	float MaxConnectionDistance = 650.f;

	bool bChainConnected = false;

	UPROPERTY()
	FOnConductorChainConnected OnConductorChainConnected;
	UPROPERTY()
	FOnConductorChainDisconnected OnConductorChainDisconnected;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ElectricityEffect;

	TArray<UNiagaraComponent> ElectricityComps;
	int CurNiagaraNum;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());

		GetAllActorsOfClass(AllConductors);
		for (ASpaceConductor CurConductor : AllConductors)
		{
			ActorsToIgnore.Add(CurConductor);				
			CurConductor.CooldownTime = ConductorCooldownTime;
		}

		for (int Index = 0, Count = AllConductors.Num() + 2; Index < Count; ++ Index)
		{
			UNiagaraComponent CurNiagaraComp = Niagara::SpawnSystemAttached(ElectricityEffect, ElectricityOrigin, n"None", FVector::ZeroVector, ActorRotation, EAttachLocation::SnapToTarget, false);
			ElectricityComps.Add(CurNiagaraComp);
		}
	
		HazeAkComp.OcclusionRefreshInterval = 0.f;
		HazeAkComp.SetStopWhenOwnerDestroyed(true);

		LastNumberOfActiveConducts = ActiveConductors.Num();
	}

	ASpaceConductor GetClosestUnmarkedConductor(FVector Position)
	{
		float MaxDistSQ = MAX_flt;
		ASpaceConductor ClosestConductor = nullptr;
		for (ASpaceConductor Conductor : AllConductors)
		{
			if (Conductor.bChainMarked)
				continue;
			float DistSQ = Conductor.ActorLocation.DistSquared2D(Position);
			if (DistSQ < MaxDistSQ)
			{
				MaxDistSQ = DistSQ;
				ClosestConductor = Conductor;
			}
		}

		return ClosestConductor;
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		for (int i = 0, Count = ElectricityComps.Num(); i < Count; ++i)
			ElectricityComps[i].Deactivate();
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int ElectricityCompsUsed = 0;
		for (ASpaceConductor Conductor : AllConductors)
			Conductor.bChainMarked = false;

		ActiveConductors.Reset();

		bool bConnectedToEnd = false;

		FVector SourceLocation = ElectricityOrigin.WorldLocation;
		FVector ElectricityLocation = ElectricityOrigin.WorldLocation;
		ASpaceConductor PreviousConductor;
		while (true)
		{
			// Check if we can connect to another conductor
			ASpaceConductor Closest = GetClosestUnmarkedConductor(SourceLocation);
			if (Closest == nullptr)
				break;

			// Stop if the closest conductor is too far away
			float MaxDistance = Closest.IsPickedUp() ? MaxConnectionDistance : MaxConnectionDistance + 50.f;
			float Distance = Closest.ActorLocation.Dist2D(SourceLocation);
			if (Distance > MaxDistance)
				break;

			// Don't connect if electricity is obstructed
			if (TraceToLocation(ElectricityLocation, Closest.ConnectPoint.WorldLocation))
				break;

			if (!Closest.bIsConnected)
			{
				Closest.bIsConnected = true;
				Closest.PlayConductorSound(ConnectToConductorEvent);
			}

			Closest.bChainMarked = true;
			ActiveConductors.Add(Closest);

			// Create electricity from previous point
			{
				UNiagaraComponent ElectricityComp = ElectricityComps[ElectricityCompsUsed];
				ElectricityCompsUsed += 1;

				ElectricityComp.Activate();
				ElectricityComp.SetNiagaraVariableVec3("User.BeamStart", ElectricityLocation);
				ElectricityComp.SetNiagaraVariableVec3("User.BeamEnd", Closest.ConnectPoint.WorldLocation);
			}

			// Check if we can connect to the end point
			float DistanceToEnd = Closest.ActorLocation.Distance(EndPoint.ActorLocation);
			if (DistanceToEnd < MaxDistance)
			{
				bConnectedToEnd = true;

				// Create electricity to end location
				UNiagaraComponent ElectricityComp = ElectricityComps[ElectricityCompsUsed];
				ElectricityCompsUsed += 1;

				ElectricityComp.Activate();
				ElectricityComp.SetNiagaraVariableVec3("User.BeamStart", Closest.ConnectPoint.WorldLocation);
				ElectricityComp.SetNiagaraVariableVec3("User.BeamEnd", EndPoint.ActorLocation);
			}

			SourceLocation = Closest.ActorLocation;
			ElectricityLocation = Closest.ConnectPoint.WorldLocation;
			PreviousConductor = Closest;
		}

		if (HasControl())
		{
			if (bConnectedToEnd && !bChainConnected)
				NetConnectChain();
			if (!bConnectedToEnd && bChainConnected)
				NetDisconnectChain();
		}

		// Disconnect any conductors we didn't find
		for (ASpaceConductor Conductor : AllConductors)
		{
			if (Conductor.bIsConnected && !Conductor.bChainMarked)
			{
				Conductor.bIsConnected = false;
				Conductor.PlayConductorSound(DisconnectToConductorEvent);
			}

			Conductor.bHasStarted = true;
		}

		// Deactivate electricity we are no longer using
		for (int i = ElectricityCompsUsed, Count = ElectricityComps.Num(); i < Count; ++i)
			ElectricityComps[i].Deactivate();

		// Update audio parameters
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::SpaceConductorsConnected, ActiveConductors.Num(), 0.f);

		if(ActiveConductors.Num() > 0 && StartLoopingConductorEvent != nullptr && !bIsPlayingLoopingEvent)
		{
			HazeAkComp.HazePostEvent(StartLoopingConductorEvent);
			bIsPlayingLoopingEvent = true;
		}
		else if(ActiveConductors.Num() == 0 && StopLoopingConductorEvent != nullptr && bIsPlayingLoopingEvent)
		{
			HazeAkComp.HazePostEvent(StopLoopingConductorEvent);
			bIsPlayingLoopingEvent = false;
		}

		SetEmitterPositions(ActiveConductors);
	}

	TArray<FTransform> EmitterPoints;	
	void SetEmitterPositions(TArray<ASpaceConductor> Conductors)
	{
		if (Conductors.Num() > 0 && StartLoopingConductorEvent != nullptr)
		{
			EmitterPoints.Reset();
			EmitterPoints.Add(GetActorTransform());						

			for (ASpaceConductor Conductor : Conductors)
				EmitterPoints.Add(Conductor.GetActorTransform());

			HazeAkComp.HazeSetMultiplePositions(EmitterPoints, AkMultiPositionType::MultiSources);
		}
	}

	bool TraceToLocation(FVector StartLocation, FVector EndLocation)
	{
		FHitResult Hit;
		System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
		return Hit.bBlockingHit;
	}

	UFUNCTION(NetFunction)
	private void NetConnectChain()
	{
		bChainConnected = true;
		OnConductorChainConnected.Broadcast();
	}

	UFUNCTION(NetFunction)
	private void NetDisconnectChain()
	{
		bChainConnected = false;
		OnConductorChainDisconnected.Broadcast();
	}
}