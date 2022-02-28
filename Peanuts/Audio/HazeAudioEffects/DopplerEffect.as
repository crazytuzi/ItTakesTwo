import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

USTRUCT()
struct FDopplerPassbyEvent
{
	UPROPERTY()
	UAkAudioEvent Event = nullptr;
	UPROPERTY()
	float ApexTime = 1.f;
	UPROPERTY()
	float Cooldown = 1.f;	
	UPROPERTY()
	float MaxDistance = 0.f;
	UPROPERTY()
	float VelocityAngle = 0.f;
	UPROPERTY()
	float MinRelativeSpeed = 0.f;

	FHazeAudioEventInstance EventInstance = FHazeAudioEventInstance();
	float CooldownTimer = 0.f;
	float MayCooldownTimer = 0.f;
	float CodyCooldownTimer = 0.f;
	bool bCanTrigger = true;
	bool bCanTriggerForMay = true;
	bool bCanTriggerForCody = true;
}

struct FHazeDopplerObserverData
{
	UObject ObserverObject;
	FVector ObserverLocation;
	FVector DirectionFromDriver;
	float DistanceToObserver;
	EHazePlayer PlayerTarget;
}

class UDopplerEffect : UHazeAudioEffect
{
	// Cached vectors for tracking observer movement, key is either AHazePlayerCharacter or UHazeListenerComponent
	TMap<UObject, FVector> ObserverPositions;
	TMap<UObject, FVector> ObserverVelos;
	TArray<UObject> ObserversToUpdate;
	
	FVector EmitterPosition;
	FVector LastEmitterPosition;

	FVector EmitterVelo;
	FVector LastEmitterVelo;

	//FVector GrindingVelo;
	//FVector LastGrindingVelo;

	float LastRtpcValue;	

	float MinDopplerDistance = 0.f;
	float MaxDopplerDistance = 0.f;
	float MaxDopplerSpeed = 2500.f;

	float VelocityScalar = 1.f;
	float SmoothingValue = 0.5;
	float Power = 1.f;

	//bool bIsGrindingDoppler = false;

	UPROPERTY()
	TArray<FDopplerPassbyEvent> PassbyEvents;

	EHazeDopplerObserverType TargetObserver = EHazeDopplerObserverType::BothListeners;
	EHazeDopplerDriverType DopplerDriver = EHazeDopplerDriverType::Emitter;

	UHazeListenerComponent ClosestListener;
	AHazePlayerCharacter ClosestPlayer;

	TArray<AHazePlayerCharacter> Players;
	TArray<UHazeListenerComponent> Listeners;

	AHazePlayerCharacter ForcedPlayerTarget = nullptr;
	UPlayerHazeAkComponent CodyHazeAkComp = nullptr;
	UPlayerHazeAkComponent MayHazeAkComp = nullptr;
	
	UPROPERTY()
	bool bDebug = false;

	UPROPERTY()
	bool bActive = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HazeAkOwner.SetShouldTrackClosestPlayer(true);
	}

	UFUNCTION()
	void SetObjectDopplerValues(bool bUpdate, float MaxSpeed = 2500.f, float MinDistance = 1000.f,  float MaxDistance = 0.f,  
	float Scale = 1.f, float Smoothing = 0.5f, float CurvePower = 1.f, 
	EHazeDopplerObserverType Observer = EHazeDopplerObserverType::ClosestListener, EHazeDopplerDriverType Driver = EHazeDopplerDriverType::Emitter, bool bGrindingDoppler = false)
	
	{
		bActive = bUpdate;
		MinDopplerDistance = MinDistance;

		if(MaxDistance != 0.f)
		{
			MaxDopplerDistance = MaxDistance;
		}
		else
		{
			MaxDopplerDistance = HazeAkOwner.ScaledMaxAttenuationRadius;
		}

		MaxDopplerSpeed = MaxSpeed;

		VelocityScalar = Scale;
		SmoothingValue = Smoothing;
		Power = CurvePower;		

		TargetObserver = Observer;	
		//bIsGrindingDoppler = bGrindingDoppler;

		if(TargetObserver == EHazeDopplerObserverType::May)
		{
			ForcedPlayerTarget = Game::GetMay();
			MayHazeAkComp = UPlayerHazeAkComponent::Get(ForcedPlayerTarget);
			ObserverPositions.FindOrAdd(ForcedPlayerTarget) = ForcedPlayerTarget.GetActorLocation();
			ObserversToUpdate.AddUnique(ForcedPlayerTarget);
		}
		else if(TargetObserver == EHazeDopplerObserverType::Cody)
		{
			ForcedPlayerTarget = Game::GetCody();		
			CodyHazeAkComp = UPlayerHazeAkComponent::Get(ForcedPlayerTarget);
			ObserverPositions.FindOrAdd(ForcedPlayerTarget) = ForcedPlayerTarget.GetActorLocation();
			ObserversToUpdate.AddUnique(ForcedPlayerTarget);
		}
		else if(TargetObserver == EHazeDopplerObserverType::BothListeners || TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{
			MayHazeAkComp = UPlayerHazeAkComponent::Get(Game::GetMay());
			CodyHazeAkComp = UPlayerHazeAkComponent::Get(Game::GetCody());

			if(TargetObserver == EHazeDopplerObserverType::BothPlayers)
			{
				Players = Game::GetPlayers();
				for(auto& Player : Players)
				{
					ObserverPositions.FindOrAdd(Player) = Player.GetActorLocation();
					ObserverVelos.FindOrAdd(Player.ListenerComponent) = Player.GetActorLocation() - ObserverPositions.FindOrAdd(Player);
					ObserversToUpdate.AddUnique(Player);
				}
			}
			else
			{
				for(AHazePlayerCharacter& Player : Players)
				{
					Listeners.Add(Player.ListenerComponent);
					ObserverPositions.FindOrAdd(Player.ListenerComponent) = Player.ListenerComponent.GetWorldLocation();
					ObserverVelos.FindOrAdd(Player.ListenerComponent) = Player.ListenerComponent.GetWorldLocation() - ObserverPositions.FindOrAdd(Player.ListenerComponent);
					ObserversToUpdate.AddUnique(Player.ListenerComponent);
				}
			}
		}

		DopplerDriver = Driver;			
	}
	
	UFUNCTION(BlueprintOverride)
	void TickEffect(float DeltaSeconds)
	{			
		if(!bEnableEffect)
			return;

		UObject RawCurrentObserver;
		// If we couldn't get our targeted observer this frame, bail
		if(!UpdateTargetObserver(RawCurrentObserver))
			return;

		EmitterPosition = UpdateEmitterPosition();

		// Query passby-sounds per relevant observer, i.e loop if both players/both listeners, else execute once per tick
		if(TargetObserver == EHazeDopplerObserverType::BothListeners)
		{
			for(auto& Listener : Listeners)
			{
				QueryPassbysForObserver(Listener, DeltaSeconds);
			}
		}
		else if(TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{
			for(auto& Player : Players)
			{
				QueryPassbysForObserver(Player, DeltaSeconds);
			}
		}
		else
		{
			QueryPassbysForObserver(RawCurrentObserver, DeltaSeconds);
		}

		// Get closest listener/player based on chosen observer type, use this to drive doppler RTPC
		// Even with both listener/player chosen, we still act upon closest as of right now
		FHazeDopplerObserverData ObserverData = GetDopplerRTPCObserverData();

		if(bActive)
		{
			const float DopplerRtpc = CalcObjectDopplerValues(ObserverData, DeltaSeconds, bActive);
			SetObjectDopplerRTPC(DopplerRtpc, bActive);
		}

		// Cache vectors from this frame for comparison on next frame
		UpdateVectors(RawCurrentObserver);
	}

	void QueryPassbysForObserver(UObject& RawCurrentObserver, float DeltaSeconds)
	{
		if(PassbyEvents.Num() == 0)
			return;

		FHazeDopplerObserverData ObserverFrameData;

		UHazeListenerComponent ListenerObserver = Cast<UHazeListenerComponent>(RawCurrentObserver);
		AHazePlayerCharacter PlayerObserver = Cast<AHazePlayerCharacter>(RawCurrentObserver);

		if(ListenerObserver == nullptr && PlayerObserver == nullptr)
			return;

		if(ListenerObserver != nullptr)
		{
			ObserverFrameData.ObserverObject = ListenerObserver;
			ObserverFrameData.ObserverLocation = ListenerObserver.GetWorldLocation();
			ObserverFrameData.DistanceToObserver = EmitterPosition.Distance(ObserverFrameData.ObserverLocation);
			ObserverFrameData.DirectionFromDriver = UpdateDirection(ObserverFrameData.ObserverLocation);

			AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(ListenerObserver.GetOwner());
			ObserverFrameData.PlayerTarget = PlayerOwner.IsMay() ? EHazePlayer::May : EHazePlayer::Cody;
		}
		else if(PlayerObserver != nullptr)
		{
			ObserverFrameData.ObserverObject = PlayerObserver;
			ObserverFrameData.ObserverLocation = PlayerObserver.GetActorLocation();			
			ObserverFrameData.DistanceToObserver = EmitterPosition.Distance(ObserverFrameData.ObserverLocation);
			ObserverFrameData.DirectionFromDriver = UpdateDirection(ObserverFrameData.ObserverLocation);		

			ObserverFrameData.PlayerTarget = PlayerObserver.IsMay() ? EHazePlayer::May : EHazePlayer::Cody;
		}

		PreparePassbyEvents(ObserverFrameData, DeltaSeconds);
	}

	FHazeDopplerObserverData GetDopplerRTPCObserverData()
	{
		FHazeDopplerObserverData ObserverData;
		switch(TargetObserver)
		{
			case(EHazeDopplerObserverType::BothListeners):
			{
				ObserverData.ObserverObject = ClosestListener;
				ObserverData.ObserverLocation = ClosestListener.GetWorldLocation();
				ObserverData.DistanceToObserver = EmitterPosition.Distance(ObserverData.ObserverLocation);
				ObserverData.DirectionFromDriver = UpdateDirection(ObserverData.ObserverLocation);
				return ObserverData;
			}
			case(EHazeDopplerObserverType::ClosestListener):
			{
				ObserverData.ObserverObject = ClosestListener;
				ObserverData.ObserverLocation = ClosestListener.GetWorldLocation();
				ObserverData.DistanceToObserver = EmitterPosition.Distance(ObserverData.ObserverLocation);
				ObserverData.DirectionFromDriver = UpdateDirection(ObserverData.ObserverLocation);
				return ObserverData;
			}
			case(EHazeDopplerObserverType::BothPlayers):
			{
				ObserverData.ObserverObject = ClosestPlayer;
				ObserverData.ObserverLocation = ClosestPlayer.GetActorLocation();
				ObserverData.DistanceToObserver = EmitterPosition.Distance(ObserverData.ObserverLocation);
				ObserverData.DirectionFromDriver = UpdateDirection(ObserverData.ObserverLocation);
				return ObserverData;
			}
			case(EHazeDopplerObserverType::ClosestPlayer):
			{
				ObserverData.ObserverObject = ClosestPlayer;
				ObserverData.ObserverLocation = ClosestPlayer.GetActorLocation();
				ObserverData.DistanceToObserver = EmitterPosition.Distance(ObserverData.ObserverLocation);
				ObserverData.DirectionFromDriver = UpdateDirection(ObserverData.ObserverLocation);
				return ObserverData;
			}
			default:
			{
				ObserverData.ObserverObject = ForcedPlayerTarget;
				ObserverData.ObserverLocation = ForcedPlayerTarget.GetActorLocation();
				ObserverData.DistanceToObserver = EmitterPosition.Distance(ObserverData.ObserverLocation);
				ObserverData.DirectionFromDriver = UpdateDirection(ObserverData.ObserverLocation);
				return ObserverData;
			}
		}
		
		return ObserverData;
	}

	bool UpdateTargetObserver(UObject& OutObserver)
	{
		if(TargetObserver == EHazeDopplerObserverType::ClosestListener)
		{
			ClosestListener = UHazeAkComponent::GetClosestListener(GetWorld(), HazeAkOwner.GetWorldLocation());
			OutObserver = ClosestListener;
			return OutObserver != nullptr;
		} 
		else if(TargetObserver == EHazeDopplerObserverType::BothListeners)
		{
			ClosestListener = UHazeAkComponent::GetClosestListener(GetWorld(), HazeAkOwner.GetWorldLocation());
			for(auto& Listener : Listeners)
			{
				if(Listener != nullptr)
					return true;
			}
		}
		else if(TargetObserver == EHazeDopplerObserverType::ClosestPlayer)
		{
			ClosestPlayer = HazeAkOwner.ClosestPlayer != nullptr ? HazeAkOwner.ClosestPlayer : HazeAkOwner.GetClosestPlayer();
			OutObserver = ClosestPlayer;
			return OutObserver != nullptr;
		}
		else if(TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{
			ClosestPlayer = HazeAkOwner.ClosestPlayer != nullptr ? HazeAkOwner.ClosestPlayer : HazeAkOwner.GetClosestPlayer();
			for(auto& Player : Players)
			{
				if(Player != nullptr)
					return true;
			}
		}
		else if(TargetObserver == EHazeDopplerObserverType::Cody)
		{
			OutObserver = Game::GetCody();
			return OutObserver != nullptr;
		}
		else if(TargetObserver == EHazeDopplerObserverType::May)
		{
			OutObserver = Game::GetMay();
			return OutObserver != nullptr;
		}

		return false;
	}

	float CalcRelevantSpeed(FVector CurrentPos, FVector LastPos, FVector OtherObjectLastPos, float DeltaSeconds)
	{
		float RelSpeed = (((CurrentPos.Distance(OtherObjectLastPos) - LastPos.Distance(OtherObjectLastPos)) / DeltaSeconds) / 100.f) * VelocityScalar;
		if(RelSpeed == 0)
		{
			RelSpeed += 0.1f;
		}

		return RelSpeed; 
	}

	float GetVeloSpeed(FVector ObserverPosition, FVector LastObserverPosition, float DeltaSeconds)
	{			
		float ObserverSpeed = (ObserverPosition - LastObserverPosition).Size() / 100.f;
		float EmitterSpeed = (EmitterPosition - LastEmitterPosition).Size() / 100.f;

		float RelSpeed = ((ObserverSpeed - EmitterSpeed) / DeltaSeconds) * VelocityScalar;
		
		return RelSpeed;
		
	}	

	bool GetRelativeVelo(FVector ObserverPosition, FVector LastObserverPosition, float DeltaSeconds, FVector& VeloVector)
	{
		// Lerp between old and new Vector to smooth out sudden changes in velocity

		//FVector LerpedEmitterVelo = FMath::VInterpTo(LastEmitterVelo, EmitterVelo, 0.5f, 1.f);
		//FVector LerpedObserverVelo = FMath::VInterpTo(LastObserverVelo, ObserverVelo, 0.5f, 1.f);		

		//System::DrawDebugSphere(LerpedEmitterVelo, 50.f, LineColor = FLinearColor::Red);
		//System::DrawDebugSphere(LerpedObserverVelo, 50.f, LineColor = FLinearColor::Purple);

		//System::DrawDebugSphere(EmitterPosition, 50.f, LineColor = FLinearColor::Red);
		//System::DrawDebugSphere(LastEmitterPosition, 50.f, LineColor = FLinearColor::Purple);		
		//System::DrawDebugSphere((EmitterPosition + EmitterVelo), 50.f, LineColor = FLinearColor::Purple);

		/*
		if(bIsGrindingDoppler)
		{
			VeloVector = GrindingVelo / DeltaSeconds;

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HazeAkOwner.GetOwner());
			AHazePlayerCharacter OtherPlayer = Player.GetOtherPlayer();

			
			
			return true;
		}
		*/

		EmitterVelo = (EmitterPosition - LastEmitterPosition);		
		FVector ObserverVelo = (ObserverPosition - LastObserverPosition);

		switch(DopplerDriver)
		{
			case EHazeDopplerDriverType::Observer:			
				VeloVector = (ObserverVelo - EmitterVelo) / DeltaSeconds;	

				if(ObserverVelo.SizeSquared() <= 0)	
					return false;	
					
				return true;
			case EHazeDopplerDriverType::Emitter: 
				VeloVector = (EmitterVelo - ObserverVelo) / DeltaSeconds;

				if(EmitterVelo.SizeSquared() <= 0)
					return false;

				return true;
			default:				
				VeloVector = (EmitterVelo - ObserverVelo) / DeltaSeconds; 					
				return true;
		}

		return true;
	}

	private float CalcObjectDopplerValues(const FHazeDopplerObserverData& ObserverData, float DeltaSeconds, bool bUpdate = bActive)
	{		
		float RelativeSpeed = CalculatedRelSpeed(ObserverData, DeltaSeconds);
		float ScaledEmitterSpeed = HazeAudio::NormalizeRTPC(RelativeSpeed, -MaxDopplerSpeed, MaxDopplerSpeed, -1.f, 1.f);

		float ObserverDistance = EmitterPosition.Distance(ObserverData.ObserverLocation) / 100.f;
		float NormalizedDistance = HazeAudio::NormalizeRTPC(ObserverDistance, MinDopplerDistance, MaxDopplerDistance, 1.f, 0.f);

		float PowDistance = FMath::Pow(NormalizedDistance, Power);

		float DopplerValue = ScaledEmitterSpeed * PowDistance;

	#if EDITOR
		{
			if(bDebug)
			{
				//Print("Rel Obs Speed: " + RelevantObserverSpeed);
				//Print("Rel Emitter Speed: " + RelevantEmitterSpeed);
				//Print("Normalized Distance: " + NormalizedDistance);
				//Print("Scaled Emitter Speed: " + ScaledEmitterSpeed);
				//Print("Doppler Value: " + DopplerValue);
			}
		}
	#endif
		
		const float RtpcValue = FMath::Lerp(DopplerValue, LastRtpcValue, SmoothingValue);	
		return RtpcValue;		
	
	}

	private void SetObjectDopplerRTPC(const float& RtpcValue, bool bUpdate)
	{	
		if(!bEnableEffect || !bUpdate)
		{
			HazeAkOwner.SetRTPCValue("Rtpc_Distance_SoundToPlayer_Doppler", 0.f, 0.f);
			return;
		}	

		if(LastRtpcValue == RtpcValue)
			return;

		HazeAkOwner.SetRTPCValue("Rtpc_Distance_SoundToPlayer_Doppler", FMath::Clamp(RtpcValue, -1.f, 1.f), 0.f);		
		LastRtpcValue = RtpcValue;		
	}
	
	UFUNCTION()
	void PlayPassbySound(UAkAudioEvent Event, float ApexTime, float CooldownTime, float MaxDistance = 0.f, float VelocityAngle = 0.f, float MinRelativeSpeed = 0.f)
	{	
		FDopplerPassbyEvent PassbyInstance;

		PassbyInstance.Event = Event;
		PassbyInstance.ApexTime = ApexTime;
		PassbyInstance.Cooldown = CooldownTime;
		PassbyInstance.MaxDistance = MaxDistance;
		PassbyInstance.VelocityAngle = VelocityAngle;
		PassbyInstance.MinRelativeSpeed = MinRelativeSpeed;

		PassbyEvents.Add(PassbyInstance);
	}

	UFUNCTION()
	void StopPassbySound(UAkAudioEvent Event = nullptr)
	{
		if(Event != nullptr)
		{
			for(int i = PassbyEvents.Num() - 1; i >= 0; i--)
			{
				if(PassbyEvents[i].Event == Event)
				{
					PassbyEvents.RemoveAtSwap(i);			
				}
			}
		}
		else			
			PassbyEvents.Empty();		
	}

	UFUNCTION()
	void StopPlayingPassbySound(UAkAudioEvent Event, int32 FadeoutTimeMs = 0)
	{
		for(int i = PassbyEvents.Num() - 1; i >= 0; i--)
		{
			if(PassbyEvents[i].Event == Event)
			{
				AkGameplay::ExecuteActionOnPlayingID(AkActionOnEventType::Stop, PassbyEvents[i].EventInstance.PlayingID, FadeoutTimeMs);		
			}
		}				
	}

	UFUNCTION()
	bool IsPassbyEventPlaying(UAkAudioEvent Event)
	{
		for(FDopplerPassbyEvent PassbyEvent : PassbyEvents)
		{
			if(PassbyEvent.Event != Event)
				continue;

			return HazeAkOwner.HazeIsEventActive(PassbyEvent.EventInstance.EventID);
		}
		 
		return false;
	}

	UFUNCTION()
	void StopAllPassBySounds()
	{
		PassbyEvents.Empty();
	}

	UFUNCTION()
	void ToggleAllPassbySounds(bool bEnabled)
	{
		for(FDopplerPassbyEvent& PassbyEvent : PassbyEvents)
		{
			PassbyEvent.bCanTrigger = bEnabled;	
			PassbyEvent.bCanTriggerForCody = bEnabled;
			PassbyEvent.bCanTriggerForMay = bEnabled;		
		}
	}

	UFUNCTION()
	void ResetPassbyTimer(UAkAudioEvent PassbyEvent)
	{
		for(FDopplerPassbyEvent& Event : PassbyEvents)
		{
			if(Event.Event != PassbyEvent)
				continue;

			Event.bCanTrigger = true;
			Event.bCanTriggerForCody = true;
			Event.bCanTriggerForMay = true;

			Event.CooldownTimer = 0.f;
		}
	}

	private void PreparePassbyEvents(FHazeDopplerObserverData& ObserverData, float DeltaSeconds)
	{	
		FVector RelVelo;
		FVector LastObserverPosition;
		ObserverPositions.Find(ObserverData.ObserverObject, LastObserverPosition);

		if(!GetRelativeVelo(ObserverData.ObserverLocation, LastObserverPosition, DeltaSeconds, RelVelo))
			return;			

		for(FDopplerPassbyEvent& PassbyEvent : PassbyEvents)
		{
			if(!CheckCanTrigger(PassbyEvent, ObserverData))
			{				
				TickCooldownTimer(PassbyEvent, ObserverData, DeltaSeconds);
				continue;
			}
			

			FVector TargetVector = (RelVelo * PassbyEvent.ApexTime);
			//FVector RelSpeedVector = (LastEmitterVelo * PassbyEvent.ApexTime);
			FVector NormalizedTargetVector = TargetVector.GetSafeNormal(); 			

			FVector NormalizedDirection = ObserverData.DirectionFromDriver.GetSafeNormal();
			
			float Dot = NormalizedDirection.DotProduct(NormalizedTargetVector);				

			float TargetVectorSize = TargetVector.Size();	
			float RelVeloSpeed = (TargetVectorSize / PassbyEvent.ApexTime) / 100.f;			
			
			if(bDebug)
			{
				Print("Dot: " + Dot);	
				Print("RelVeloSpeed: " + RelVeloSpeed);	

				//System::DrawDebugArrow(EmitterPosition, (EmitterPosition + (RelSpeedVector * 100.f)));
				System::DrawDebugArrow(EmitterPosition, (EmitterPosition + (RelVeloSpeed * 10.f)), LineColor = FLinearColor::Red);
				System::DrawDebugLine(EmitterPosition, (EmitterPosition + (TargetVector)), LineColor = FLinearColor::Yellow);
				System::DrawDebugSphere(EmitterPosition, 50.f, LineColor = FLinearColor::Green);				

				//System::DrawDebugConeInDegrees(EmitterPosition, RelSpeedVector * 1000.f, 3000.f, FMath::Lerp(180.f, 0.f, 0.9f), FMath::Lerp(180.f, 0.f, 0.9f));
			}	

			if (Dot < PassbyEvent.VelocityAngle)				
				continue;

			if(TargetVectorSize >= ObserverData.DistanceToObserver && bEnableEffect)
			{
				if(PassbyEvent.MaxDistance != 0 && ObserverData.DistanceToObserver > PassbyEvent.MaxDistance)
					continue;					

				PostPassbyEvent(PassbyEvent, RelVeloSpeed, ObserverData);			

				if(bDebug)
				{
					System::DrawDebugSphere(TargetVector + EmitterPosition, Duration = 3.f);
				}					
			}
		}
	}

	FVector UpdateEmitterPosition()
	{		
		return HazeAkOwner.GetWorldLocation();
	}

	float CalculatedRelSpeed(FHazeDopplerObserverData ObserverData, float DeltaSeconds)
	{	
		FVector LastObserverPosition;
		ObserverPositions.Find(ObserverData.ObserverObject, LastObserverPosition);

		switch(DopplerDriver)
		{
			case EHazeDopplerDriverType::Emitter:
				return CalcRelevantSpeed(EmitterPosition, LastEmitterPosition, LastObserverPosition, DeltaSeconds);
			case EHazeDopplerDriverType::Observer:
				return CalcRelevantSpeed(ObserverData.ObserverLocation, LastObserverPosition, LastEmitterPosition, DeltaSeconds);
			case EHazeDopplerDriverType::Both:
				return GetVeloSpeed(ObserverData.ObserverLocation, LastObserverPosition, DeltaSeconds);
			default:
				return CalcRelevantSpeed(EmitterPosition, LastEmitterPosition, LastObserverPosition, DeltaSeconds);
		}	

		return 0;
	}

	bool CheckCanTrigger(FDopplerPassbyEvent& PassbyEvent, FHazeDopplerObserverData ObserverData)
	{
		if(TargetObserver == EHazeDopplerObserverType::BothListeners)
		{	
			if(ObserverData.PlayerTarget == EHazePlayer::May)		
				return PassbyEvent.bCanTriggerForMay && !Game::GetMay().IsPlayerDead();
			else
				return PassbyEvent.bCanTriggerForCody && !Game::GetCody().IsPlayerDead();					
		}
		else if(TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{
			if(ObserverData.PlayerTarget == EHazePlayer::May)
				return PassbyEvent.bCanTriggerForMay && !Game::GetMay().IsPlayerDead();
			else
				return PassbyEvent.bCanTriggerForCody && !Game::GetCody().IsPlayerDead();			
		}
		else
		{	
			AHazePlayerCharacter PlayerTarget = ForcedPlayerTarget != nullptr ? ForcedPlayerTarget : nullptr;
			if(PlayerTarget == nullptr)
			{
				if(TargetObserver == EHazeDopplerObserverType::ClosestListener)
					PlayerTarget = Cast<AHazePlayerCharacter>(ClosestListener.GetOwner());
				else
					PlayerTarget = ClosestPlayer;				
			}

			if(PlayerTarget == nullptr)
				return false;			
			
			return PassbyEvent.bCanTrigger && !PlayerTarget.IsPlayerDead();			
		}
	}

	void TickCooldownTimer(FDopplerPassbyEvent& PassbyEvent, FHazeDopplerObserverData ObserverData, float DeltaSeconds)
	{
		if(TargetObserver == EHazeDopplerObserverType::BothListeners ||TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{			
			if(ObserverData.PlayerTarget == EHazePlayer::May)					
			{
				PassbyEvent.MayCooldownTimer += DeltaSeconds;
				PassbyEvent.bCanTriggerForMay = PassbyEvent.MayCooldownTimer >= PassbyEvent.Cooldown;

				if(PassbyEvent.bCanTriggerForMay)
					PassbyEvent.MayCooldownTimer = 0.f;	
			}
			else
			{
				PassbyEvent.CodyCooldownTimer += DeltaSeconds;
				PassbyEvent.bCanTriggerForCody = PassbyEvent.CodyCooldownTimer >= PassbyEvent.Cooldown;

				if(PassbyEvent.bCanTriggerForCody)
					PassbyEvent.CodyCooldownTimer = 0.f;
			}				
		}	
		else
		{
			PassbyEvent.CooldownTimer += DeltaSeconds;
			PassbyEvent.bCanTrigger = PassbyEvent.CooldownTimer >= PassbyEvent.Cooldown;

			if(PassbyEvent.bCanTrigger)
				PassbyEvent.CooldownTimer = 0.f;	
		}
	}

	void PostPassbyEvent(FDopplerPassbyEvent& PassbyEvent, const float RelVeloSpeed, FHazeDopplerObserverData& ObserverData)
	{
		UHazeAkComponent WantedHazeAkComp = HazeAkOwner;

		if(TargetObserver == EHazeDopplerObserverType::BothListeners || TargetObserver == EHazeDopplerObserverType::BothPlayers)
		{
			if(ObserverData.PlayerTarget == EHazePlayer::May)
			{
				if(DopplerDriver == EHazeDopplerDriverType::Observer)
					WantedHazeAkComp = MayHazeAkComp;

				PassbyEvent.bCanTriggerForMay = false;
			}
			else
			{
				if(DopplerDriver == EHazeDopplerDriverType::Observer)
					WantedHazeAkComp = CodyHazeAkComp;
										
				PassbyEvent.bCanTriggerForCody = false;
			}
		}		
		else
			PassbyEvent.bCanTrigger = false;	

		if(PassbyEvent.MinRelativeSpeed != 0)
		{
			float NormRelativeVelo = HazeAudio::NormalizeRTPC01(RelVeloSpeed, 0.f, PassbyEvent.MinRelativeSpeed);
			SetRelativeVelocityRtpc(WantedHazeAkComp, NormRelativeVelo);
		}

		PassbyEvent.EventInstance = WantedHazeAkComp.HazePostEvent(PassbyEvent.Event);
	}

	void SetRelativeVelocityRtpc(UHazeAkComponent HazeAkComp, float RelVeloValue)
	{
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterObjectRelativeVelocityDelta, RelVeloValue);
	}

	FVector UpdateDirection(FVector ObserverPosition)
	{
		switch(DopplerDriver)
		{
			case EHazeDopplerDriverType::Observer:
				return EmitterPosition - ObserverPosition;

			default:
				return ObserverPosition - EmitterPosition;
		}

		return FVector();
	}

	void UpdateVectors(UObject RawCurrentObserver)
	{
		LastEmitterPosition = EmitterPosition;
		LastEmitterVelo = EmitterVelo;

		TMap<UObject, FVector> TempObserverPositions = ObserverPositions;
		for(auto& Elem : TempObserverPositions)
		{
			AHazePlayerCharacter PlayerObserver = Cast<AHazePlayerCharacter>(Elem.Key);
			if(PlayerObserver != nullptr)
			{
				ObserverPositions.FindOrAdd(PlayerObserver) = PlayerObserver.GetActorLocation();
				ObserverVelos.FindOrAdd(PlayerObserver) = PlayerObserver.GetActorLocation();
			}
			else
			{
				UHazeListenerComponent ListenerObserver = Cast<UHazeListenerComponent>(Elem.Key);
				if(ListenerObserver != nullptr)
				{
					ObserverPositions.FindOrAdd(ListenerObserver) = ListenerObserver.GetWorldLocation();
					ObserverVelos.FindOrAdd(ListenerObserver) = ListenerObserver.GetWorldLocation();
				}
			}		
		}

	}

	UFUNCTION()
	void SetGrindingVelocity(FVector CurrVelo)
	{
		//GrindingVelo = CurrVelo;
		//LastGrindingVelo = GrindingVelo;
	}

	UFUNCTION(BlueprintOverride)
	void OnToggleEnabled(bool bEnabled)
	{
		if(PassbyEvents.Num() > 0)
			ToggleAllPassbySounds(bEnabled);

		if(bEnabled)
		{				
			ClosestPlayer = HazeAkOwner.ClosestPlayer;
			ClosestListener = UHazeAkComponent::GetClosestListener(GetWorld(), HazeAkOwner.GetWorldLocation());		

			UObject RawCurrentObserver;
			if(UpdateTargetObserver(RawCurrentObserver))
			{
				EmitterPosition = UpdateEmitterPosition();
				UpdateVectors(RawCurrentObserver);
			}	
		}
		else
		{
			for(FDopplerPassbyEvent& PassbyEvent : PassbyEvents)
			{
				ResetPassbyTimer(PassbyEvent.Event);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemove()
	{		
		if (HazeAkOwner.bIsEnabled)
		{
			HazeAkOwner.SetRTPCValue("Rtpc_Distance_SoundToPlayer_Doppler", 0.f, 0.f);
			if(PassbyEvents.Num() > 0)
				StopPassbySound();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanDisable()
	{
		if(bEnableEffect)
		{
			float MaxRange = FMath::Max(HazeAkOwner.ScaledMaxAttenuationRadius, MaxDopplerDistance);
			if(MaxRange > 0)
			{
				float DistToClosestPlayer = HazeAkOwner.GetClosestPlayer().GetActorLocation().Distance(HazeAkOwner.GetWorldLocation());
				if(DistToClosestPlayer < MaxRange)
					return false;
			}

			if(PassbyEvents.Num() > 0)
				return false;		
		}

		return true;
	}
}