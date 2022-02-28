
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Tree.Wasps.Audio.WaspVOManager;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;

class UWaspVOEffortsCapability : UHazeCapability
{
	AHazeCharacter WaspOwner;
	UWaspBehaviourComponent BehaviourComp;
	UWaspRespawnerComponent WaspRespawnComp;
	UWaspHealthComponent WaspHealthComp;
	UHazeAkComponent WaspHazeAkComp;
	UWaspVOManager VOManager;
	FWaspVOEventData VOEventData;

	private EWaspState LastState;
	private FHazeAudioEventInstance CurrentVOEventInstance;
	private bool bWasPlaying = false;
	private bool bDidResetSap = false;
	private float DurationSinceLastVo = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WaspOwner = Cast<AHazeCharacter>(Owner);
		BehaviourComp = UWaspBehaviourComponent::Get(WaspOwner);
		WaspRespawnComp = UWaspRespawnerComponent::Get(WaspOwner);
		WaspHealthComp = UWaspHealthComponent::Get(WaspOwner);
		WaspHazeAkComp = UHazeAkComponent::Get(WaspOwner);
		VOManager = UWaspVOManager::Get(Owner.Level.LevelScriptActor);

		if(VOManager != nullptr)
			VOEventData = VOManager.GetNextAvaliableVOEventData();

		WaspRespawnComp.OnReset.AddUFunction(this, n"OnWaspReset");
		WaspHealthComp.OnDie.AddUFunction(this, n"OnWaspDie");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}	

	UFUNCTION()
	void OnWaspReset()		
	{
		if(VOManager != nullptr)
			VOEventData = VOManager.GetNextAvaliableVOEventData();
	}

	UFUNCTION()
	void OnWaspDie(AHazeActor Wasp)
	{
		if(WaspHazeAkComp.EventInstanceIsPlaying(CurrentVOEventInstance))
			WaspHazeAkComp.HazeStopEvent(CurrentVOEventInstance.PlayingID);
		
		WaspHazeAkComp.HazePostEvent(VOEventData.OnKilledEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bWasPlaying && !WaspHazeAkComp.EventInstanceIsPlaying(CurrentVOEventInstance))
		{
			DurationSinceLastVo += DeltaTime;
			if(DurationSinceLastVo > 0.5f)
				bWasPlaying = false;
		}

		EWaspState CurrentState = BehaviourComp.State;
		if(WaspStateChanged(CurrentState))
			PerformVO(CurrentState);

		if(CurrentState == EWaspState::Stunned && WaspHazeAkComp.EventInstanceIsPlaying(CurrentVOEventInstance))
		{
			WaspHazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasp_AttachedSapAmount", WaspHealthComp.SapMass);
			bDidResetSap = false;
		}
		
		if(CurrentState != EWaspState::Stunned && !bDidResetSap)
		{
			WaspHazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasp_AttachedSapAmount", 0);
			bDidResetSap = true;
		}
	}

	bool WaspStateChanged(EWaspState& OutNewState)
	{
		if(LastState == BehaviourComp.State)
			return false;

		OutNewState = BehaviourComp.State;
		LastState = OutNewState;
		return true;
	}

	void GetStateVOEvent(const EWaspState& CurrentState, UAkAudioEvent& OutEvent, UAnimSequence& OutAnim)
	{
		switch(CurrentState)
		{
			case(EWaspState::Idle):
				OutEvent = VOEventData.OnIdleEvent;				
				break;
			case(EWaspState::Combat):
				OutEvent = VOEventData.OnAggroEvent;
				OutAnim = GetRandomFaceAnim(VOEventData.OnAggroAnim);
				break;
			case(EWaspState::Telegraphing):
				OutEvent = VOEventData.OnTauntEvent;
				OutAnim = GetRandomFaceAnim(VOEventData.OnTauntAnim);
				break;
			case(EWaspState::Attack):
				OutEvent = VOEventData.OnAttackPlayerEvent;
				OutAnim = GetRandomFaceAnim(VOEventData.OnAttackAnim);
				break;
			case(EWaspState::Stunned):
				OutEvent = VOEventData.OnStunnedEvent;
				OutAnim = GetRandomFaceAnim(VOEventData.OnStunnedAnim);
				break;
			case(EWaspState::Recover):
				OutEvent = VOEventData.OnRecoverEvent;
				OutAnim = GetRandomFaceAnim(VOEventData.OnRecoverAnim);
				break;			
		}
	}

	UAnimSequence GetRandomFaceAnim(const TArray<UAnimSequence>& Anims)
	{
		if (Anims.Num() == 0)
			return nullptr;

		int RandIndex = FMath::RandRange(0, Anims.Num() - 1);
		return Anims[RandIndex];
	}

	void PerformVO(const EWaspState& CurrentState)
	{
		UAkAudioEvent VoEvent;
		UAnimSequence AnimSequence = nullptr;
		GetStateVOEvent(CurrentState, VoEvent, AnimSequence);

		if(WaspHazeAkComp.EventInstanceIsPlaying(CurrentVOEventInstance))
			WaspHazeAkComp.HazeStopEvent(CurrentVOEventInstance.PlayingID, 250.f);

		// We only play audio for stunned by sap if the wasp was talking before it got stunned
		else if(CurrentState == EWaspState::Stunned && !bWasPlaying)
			return;
		
		CurrentVOEventInstance = WaspHazeAkComp.HazePostEvent(VoEvent);
		if(AnimSequence != nullptr)
			WaspOwner.PlayFaceAnimation(FHazeAnimationDelegate(), Animation = AnimSequence);

		DurationSinceLastVo = 0.f;
		bWasPlaying = true;
	}
}