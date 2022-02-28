import Cake.LevelSpecific.Garden.Greenhouse.BossDestroyableBeamPlant;
import Peanuts.Audio.AudioStatics;

class UBossDestroyableBeamPlantAudioCapability : UHazeCapability
{
	ABossDestroyableBeamPlant BeamPlant;	

	UPROPERTY()
	UAkAudioEvent OnBeamPlantSpawnEvent;

	UPROPERTY()
	UAkAudioEvent OnBeamPlantStartGooAttackEvent;

	UPROPERTY()
	UAkAudioEvent OnStartGooBeamImpactEvent;
	
	UPROPERTY()
	UAkAudioEvent OnStopGooBeamImpactEvent;

	UPROPERTY()
	UAkAudioEvent OnBeamPlantStopGooAttackEvent;

	UPROPERTY()
	UAkAudioEvent OnBeamPlantDespawnEvent;

	UPROPERTY()
	UAkAudioEvent OnTakeDamageEvent;

	private bool bGooBeamActive = false;

	UPROPERTY()
	const float BeamActivationTimeLerpDuration = 5.f;

	float BeamActiveTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BeamPlant = Cast<ABossDestroyableBeamPlant>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BeamPlant.IsActorDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BeamPlant.HazeAkComp.HazePostEvent(OnBeamPlantSpawnEvent);
		BeamPlant.OnPlantDestroyed.AddUFunction(this, n"OnPlantDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioStartedGooBeam") == EActionStateStatus::Active)
		{
			BeamPlant.HazeAkComp.HazePostEvent(OnBeamPlantStartGooAttackEvent);
			BeamPlant.GooImpactHazeAkComp.HazePostEvent(OnStartGooBeamImpactEvent);
			bGooBeamActive = true;
			BeamActiveTime = 0.f;			
		}

		if(bGooBeamActive)
		{
			const float NormalizedBeamActiveTime = BeamActiveTime / BeamActivationTimeLerpDuration;
			BeamActiveTime += DeltaTime;
			BeamPlant.GooImpactHazeAkComp.SetWorldLocation(BeamPlant.BossBeamPlant.ImpactLocation);

			if(BeamActiveTime <= BeamActivationTimeLerpDuration)
			{
				BeamPlant.HazeAkComp.SetRTPCValue("Rtpc_Character_Bosses_Joy_DestroyableBeamPlant_Beam_Active_Duration", NormalizedBeamActiveTime);
				BeamPlant.GooImpactHazeAkComp.SetRTPCValue("Rtpc_Character_Bosses_Joy_DestroyableBeamPlant_Beam_Active_Duration", NormalizedBeamActiveTime);
			}
		}

		if(ConsumeAction(n"AudioStoppedGooBeam") == EActionStateStatus::Active)
		{
			BeamPlant.HazeAkComp.HazePostEvent(OnBeamPlantStopGooAttackEvent);
			BeamPlant.GooImpactHazeAkComp.HazePostEvent(OnStopGooBeamImpactEvent);
			bGooBeamActive = false;
		}
	}

	UFUNCTION()
	void OnPlantDestroyed()
	{
		BeamPlant.HazeAkComp.HazePostEvent(OnBeamPlantDespawnEvent);
		BeamPlant.OnPlantDestroyed.UnbindObject(this);

		if(bGooBeamActive)
		{
			BeamPlant.HazeAkComp.HazePostEvent(OnBeamPlantStopGooAttackEvent);
			BeamPlant.GooImpactHazeAkComp.HazePostEvent(OnStopGooBeamImpactEvent);
		}

		bGooBeamActive = false;
	}
}