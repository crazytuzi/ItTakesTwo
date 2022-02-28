import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;

class UCourtyardTrainAudioCapability : UHazeCapability
{
	ACourtyardTrain Train;
	UHazeAkComponent TrainHazeAkComp;
	UHazeAkComponent TrainChimneyHazeAkComp;	

	UPROPERTY(Category = "Train")
	UAkAudioEvent StartMovingEvent;

	UPROPERTY(Category = "Train")
	UAkAudioEvent EnterTrainEvent;

	UPROPERTY(Category = "Train")
	UAkAudioEvent ExitTrainEvent;

	UPROPERTY(Category = "Train")
	UAkAudioEvent RunOverPlayerEvent;

	UPROPERTY(Category = "Whistle")
	UAkAudioEvent StartWhistleEvent;

	UPROPERTY(Category = "Whistle")
	UAkAudioEvent StopWhistleEvent;

	UPROPERTY(Category = "Steam")
	UAkAudioEvent StartSteamEvent;

	private float LastTrainVelocityRtpcValue = 0.f;
	private float LastTrainBordedRtpcValue = 0.f;
		
	private bool bSteamActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Train = Cast<ACourtyardTrain>(Owner);
		TrainHazeAkComp = UHazeAkComponent::Create(Owner, n"TrainHazeAkComp");
		TrainChimneyHazeAkComp = UHazeAkComponent::Create(Owner, n"TrainChimneyHazeAkComp");

		Train.OnChimneyPulse.AddUFunction(this, n"OnChimneyPulse");

		TrainHazeAkComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		TrainChimneyHazeAkComp.AttachTo(Train.ChimneyNiagaraComp, AttachType = EAttachLocation::KeepRelativeOffset);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TrainHazeAkComp.HazePostEvent(StartMovingEvent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		SetMultiplePositions();

		if(ConsumeAction(n"AudioStartedTrainInteraction") == EActionStateStatus::Active)
			TrainHazeAkComp.HazePostEvent(EnterTrainEvent);

		if(ConsumeAction(n"AudioCanceledTrainInteraction") == EActionStateStatus::Active)
			TrainHazeAkComp.HazePostEvent(ExitTrainEvent);

		if(ConsumeAction(n"AudioStartedWhistle") == EActionStateStatus::Active)
		{
			//TrainChimneyHazeAkComp.HazePostEvent(StartWhistleEvent);
		}
		
		if(ConsumeAction(n"AudioTrainHitPlayer") == EActionStateStatus::Active)
			TrainHazeAkComp.HazePostEvent(RunOverPlayerEvent);

		const float NormalizedSpeed = HazeAudio::NormalizeRTPC01(Train.CurrentSpeed, 0.f, 2000.f);
		if(NormalizedSpeed != LastTrainVelocityRtpcValue)
		{
			TrainHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_CourtyardTrain_Speed", NormalizedSpeed);
			TrainChimneyHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_CourtyardTrain_Speed", NormalizedSpeed);
			LastTrainVelocityRtpcValue = NormalizedSpeed;
		}
	}
	
	void SetMultiplePositions()
	{
		TArray<FAkSoundPosition> EmitterPositions;

		for(AHazePlayerCharacter& Player : Game::GetPlayers())
		{
			float ShortestDistSqrd = MAX_flt;

			FVector FinalOutLocation;
			UStaticMeshComponent ClosestMesh;

			FVector TrainLocation = Train.Mesh.GetWorldLocation();
			FVector PlayerLocation = Player.GetActorCenterLocation();
			
			const float TrainDistSqrd = TrainLocation.DistSquared(PlayerLocation);
			if(TrainDistSqrd < ShortestDistSqrd)
			{
				ShortestDistSqrd = TrainDistSqrd;
				ClosestMesh = Train.Mesh;
			}

			for(ACourtyardTrainCarriage& Carriage : Train.Carriages)
			{	
				FVector MeshLocation = Carriage.Mesh.GetWorldLocation(); 		
				const float CarriageDistSqrd = MeshLocation.DistSquared(PlayerLocation);

				if(CarriageDistSqrd < ShortestDistSqrd)
				{
					ShortestDistSqrd = CarriageDistSqrd;
					ClosestMesh = Carriage.Mesh;
				}
			}

			if(ClosestMesh != nullptr)
			{
				FinalOutLocation = ClosestMesh.GetWorldLocation();
				EmitterPositions.Add(FAkSoundPosition(FinalOutLocation));
			}
		}

		if(EmitterPositions.Num() == 0)
			return;
			
		TrainHazeAkComp.HazeSetMultiplePositions(EmitterPositions);	
	}

	UFUNCTION()
	void OnChimneyPulse()
	{
		if (!IsActive())
			return;

		TrainChimneyHazeAkComp.HazePostEvent(StartSteamEvent);
	}

}