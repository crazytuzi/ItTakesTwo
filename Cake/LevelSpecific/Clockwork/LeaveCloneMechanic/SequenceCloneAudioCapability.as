import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.SequenceCloneActor;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;

class USequenceCloneAudioCapability : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent OnCloneActivated;

	UPROPERTY()
	UAkAudioEvent OnCloneDeactivated;

	UPROPERTY()
	UAkAudioEvent OnMayCloneActivated;

	UPROPERTY()
	UAkAudioEvent OnTeleportActivated;

	UPROPERTY()
	UAkAudioEvent OnTeleportCompleted;

	ASequenceCloneActor CloneOwner;	
	AHazePlayerCharacter PlayerOwner;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UTimeControlSequenceComponent SequenceComp;
	TArray<AHazePlayerCharacter> Players;

	private float LastCloneDistanceRtpcValue = 0.f;

	private FHazeAudioEventInstance ActiveCloneInstance;
	private FHazeAudioEventInstance MayActivatedEventInstance;

	private bool bChargeWasCompleted = false;
	private bool bAudioCloneActive = false;
	private bool bWasChargingClone = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);					
		SequenceComp = UTimeControlSequenceComponent::Get(PlayerOwner);		
		Players = Game::GetPlayers();
		PlayerHazeAkComp = PlayerOwner.PlayerHazeAkComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SequenceComp.bStartedChargingClone)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ASequenceCloneActor ActiveClone = SequenceComp.GetClone();
		if(ActiveClone == nullptr)
			return;

		ActiveClone.HazeAkComp.bUseAutoDisable = false;	
		bAudioCloneActive = true;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SequenceComp.IsCloneActive() || bAudioCloneActive)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(IsActioning(ActionNames::SecondaryLevelAbility))
        	return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bChargeWasCompleted = false;

		if(PlayerHazeAkComp.EventInstanceIsPlaying(MayActivatedEventInstance))
			PlayerHazeAkComp.HazeStopEvent(MayActivatedEventInstance.PlayingID, 100.f, EAkCurveInterpolation::SCurve);

		ASequenceCloneActor ActiveClone = SequenceComp.GetClone();
		if(ActiveClone != nullptr)
			ActiveClone.HazeAkComp.HazePostEvent(OnCloneDeactivated);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		ASequenceCloneActor ActiveClone = SequenceComp.GetClone();
		if(ActiveClone == nullptr)
			return;		

		if(CloneChargeWasCanceled())
		{
			NetCloneChargeWasCanceled();
		}

		if(ConsumeAction(n"AudioChargeWasCompleted") == EActionStateStatus::Active)
		{
			bChargeWasCompleted = true;
			bWasChargingClone = false;
		}

		if(ConsumeAction(n"AudioStartedChargingClone") == EActionStateStatus::Active)
		{
			if(PlayerHazeAkComp.EventInstanceIsPlaying(MayActivatedEventInstance))
				PlayerHazeAkComp.HazeStopEvent(MayActivatedEventInstance.PlayingID);
				
			MayActivatedEventInstance = PlayerHazeAkComp.HazePostEvent(OnMayCloneActivated);
		}

		if(ConsumeAction(n"AudioCloneCreated") == EActionStateStatus::Active)
		{
			if(ActiveClone.HazeAkComp.EventInstanceIsPlaying(ActiveCloneInstance))
				ActiveClone.HazeAkComp.HazeStopEvent(ActiveCloneInstance.PlayingID);

			ActiveCloneInstance = ActiveClone.HazeAkComp.HazePostEvent(OnCloneActivated);
		}

		AHazePlayerCharacter ClosestPlayer = nullptr;
		float ClosestDist = MAX_flt;

		for(AHazePlayerCharacter& Player : Players)
		{
			const float DistSqrd = ActiveClone.HazeAkComp.GetWorldLocation().DistSquared(Player.GetActorLocation());			
			if(DistSqrd > ClosestDist)
				continue;

			ClosestPlayer = Player;
			ClosestDist = DistSqrd;
		}

		const float Dist = ActiveClone.HazeAkComp.GetWorldLocation().Distance(ClosestPlayer.GetActorLocation());
		const float NormalizedDistanceRtpc = HazeAudio::NormalizeRTPC01(Dist, 0.f, ActiveClone.HazeAkComp.ScaledMaxAttenuationRadius);

		if(NormalizedDistanceRtpc != LastCloneDistanceRtpcValue)
		{
			ActiveClone.HazeAkComp.SetRTPCValue("Rtpc_Gadget_Clone_Distance", NormalizedDistanceRtpc);
			LastCloneDistanceRtpcValue = NormalizedDistanceRtpc;
		}

		if(ConsumeAction(n"AudioActivatedTeleport") == EActionStateStatus::Active)
		{
			PlayerHazeAkComp.HazePostEvent(OnTeleportActivated);
		}

		if(ConsumeAction(n"AudioCompletedTeleport") == EActionStateStatus::Active)
		{
			PlayerHazeAkComp.HazePostEvent(OnTeleportCompleted);	
			bAudioCloneActive = false;		
		}		

		if(ConsumeAction(n"AudioCloneDestroyed") == EActionStateStatus::Active)
		{
			bAudioCloneActive = false;
		}
	}	

	bool CloneChargeWasCanceled()
	{
		if(!HasControl())
			return false;

		bool bIsChargingClone = IsActioning(ActionNames::SecondaryLevelAbility) && !bChargeWasCompleted;

		if(bWasChargingClone && !bIsChargingClone)
		{
			bWasChargingClone = false;
			return true;
		}

		bWasChargingClone = IsActioning(ActionNames::SecondaryLevelAbility) && !bChargeWasCompleted;
		return false;
	}

	UFUNCTION(NetFunction)
	void NetCloneChargeWasCanceled()
	{
		ASequenceCloneActor ActiveClone = SequenceComp.GetClone();
		if(ActiveClone == nullptr)
			return;		

		if(ActiveClone.HazeAkComp.EventInstanceIsPlaying(ActiveCloneInstance))
			ActiveClone.HazeAkComp.HazeStopEvent(ActiveCloneInstance.PlayingID);

		if(PlayerHazeAkComp.EventInstanceIsPlaying(MayActivatedEventInstance))
			PlayerHazeAkComp.HazeStopEvent(MayActivatedEventInstance.PlayingID);

		bChargeWasCompleted = false;
	}
}