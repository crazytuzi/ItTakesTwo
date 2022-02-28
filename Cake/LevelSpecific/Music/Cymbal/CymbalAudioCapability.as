import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class UCymbalAudioCapability : UHazeCapability
{
	UPROPERTY(Category = "Throw")
	UAkAudioEvent OnThrowCymbalEvent;

	UPROPERTY(Category = "Throw")
	UAkAudioEvent OnCatchCymbalEvent;

	UPROPERTY(Category = "Throw")
	UAkAudioEvent OnUnequipCymbalEvent;

	UPROPERTY(Category = "Throw")
	UAkAudioEvent OnStartReturn;

	UPROPERTY(Category = "Impact")
	UAkAudioEvent OnCymbalImpactEvent;

	UPROPERTY(Category = "Shielding")
	UAkAudioEvent OnStartShieldingEvent;

	UPROPERTY(Category = "Shielding")
	UAkAudioEvent OnStopShieldingEvent;

	UPROPERTY(Category = "Shielding")
	UAkAudioEvent OnShieldImpactEvent;

	UPROPERTY(Category = "Shielding")
	UAkAudioEvent OnStopShieldImpactEvent;

	UPROPERTY(Category = "Doppler")
	UAkAudioEvent OnCymbalPassbyEvent;

	UPROPERTY(Category = "Doppler")
	float PassbyApexTime;

	UPROPERTY(Category = "Doppler")
	float PassbyCooldown;

	UPROPERTY(Category = "Doppler")
	float PassbyVelocityAngle;

	AHazePlayerCharacter Player;
	ACymbal Cymbal;
	UCymbalComponent CymbalComp;
	UHazeAkComponent CymbalHazeAkComp;
	UCymbalSettings CymbalSettings;

	UDopplerEffect CymbalDoppler;

	FVector LastCymbalLocation;
	private bool bCymbalCaughtHandled = true;
	private float LastIsReturningValue = -1.f;
	private bool bCymbalShieldBlocking = false;
	private bool bPendingHit = false;
	private bool bHasPlayedImpact = false;

	FHazeAudioEventInstance OnReturningEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CymbalComp = UCymbalComponent::Get(Owner);
		Cymbal = CymbalComp.CymbalActor;
		CymbalHazeAkComp = UHazeAkComponent::GetOrCreate(Cymbal);
		CymbalSettings = GetCymbalSettingsFromPlayer(Player);

		if(OnCymbalPassbyEvent != nullptr)
		{
			CymbalDoppler = Cast<UDopplerEffect>(CymbalHazeAkComp.AddEffect(UDopplerEffect::StaticClass(), bStartEnabled = false));
			CymbalDoppler.SetObjectDopplerValues(false, Observer = EHazeDopplerObserverType::May);
			
			CymbalDoppler.PlayPassbySound(OnCymbalPassbyEvent, PassbyApexTime, PassbyCooldown, VelocityAngle = PassbyVelocityAngle);
			CymbalDoppler.ForcedPlayerTarget = Player.OtherPlayer;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Check alive first
		if(IsPlayerDead(Player))
			return EHazeNetworkActivation::DontActivate;

		if(CymbalComp.bThrowWithoutAim)
			return EHazeNetworkActivation::ActivateLocal;

		if(CymbalComp.bAiming)
			return EHazeNetworkActivation::ActivateLocal;

		if(CymbalComp.bShieldActive)
			return EHazeNetworkActivation::ActivateLocal;

		if(CymbalComp.bCymbalAudioOnFlying)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		if(CymbalComp.bShieldActive)
			CymbalHazeAkComp.HazePostEvent(OnStartShieldingEvent);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Check alive first
		if(IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		// Always check if we have overriden activation due to flying first
		if(CymbalComp.bCymbalAudioOnFlying)	
			return EHazeNetworkDeactivation::DontDeactivate;

		if(CymbalComp.bCymbalEquipped && !CymbalComp.bAiming && !CymbalComp.bShieldActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(CymbalComp.bCymbalWasCaught && bCymbalCaughtHandled)
			return EHazeNetworkDeactivation::DeactivateLocal;		

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CymbalHazeAkComp.HazePostEvent(OnUnequipCymbalEvent);
		if(ConsumeAction(n"AudioCymbalCatch") == EActionStateStatus::Active)
		{
			CymbalHazeAkComp.HazePostEvent(OnCatchCymbalEvent);
			bCymbalCaughtHandled = true;

			if(CymbalDoppler != nullptr)
				CymbalDoppler.SetEnabled(false);
		}
		else if(IsPlayerDead(Player))
		{
			CymbalHazeAkComp.HazeStopEvent();
		}

		bPendingHit = false;
		bHasPlayedImpact = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioUnequipCymbal") == EActionStateStatus::Active)
		{
			Player.PlayerHazeAkComp.HazePostEvent(OnUnequipCymbalEvent);
		}

		if(ConsumeAction(n"AudioCymbalThrow") == EActionStateStatus::Active)
		{
			CymbalHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Gadgets_Cymbal_Direction", 1.f);
			LastIsReturningValue = 1.f;

			CymbalHazeAkComp.HazePostEvent(OnThrowCymbalEvent);	

			if(CymbalDoppler != nullptr)		
				CymbalDoppler.SetEnabled(true);

			bCymbalCaughtHandled = false;
		}

		if(ConsumeAction(n"AudioCymbalCatch") == EActionStateStatus::Active)
		{
			CymbalHazeAkComp.HazePostEvent(OnCatchCymbalEvent);
			bHasPlayedImpact = false;

			if(CymbalDoppler != nullptr)
				CymbalDoppler.SetEnabled(false);
		}

		if(ConsumeAction(n"AudioOnCymbalHit") == EActionStateStatus::Active && !bHasPlayedImpact)
		{
			CymbalHazeAkComp.HazePostEvent(OnCymbalImpactEvent);
			bHasPlayedImpact = true;
		}

		if(ConsumeAction(n"AudioShieldImpact") == EActionStateStatus::Active)
		{
			CymbalHazeAkComp.HazePostEvent(OnShieldImpactEvent);
			bCymbalShieldBlocking = true;
		}

		if(bCymbalShieldBlocking && CymbalComp.ShieldImpactingActors.Num() == 0)
		{
			CymbalHazeAkComp.HazePostEvent(OnStopShieldImpactEvent);
			bCymbalShieldBlocking = false;
		}

		if(!bCymbalCaughtHandled)
		{
			FVector CymbalOwnerLocation =  Player.GetActorLocation();
			FVector CymbalLocation = Cymbal.GetActorLocation();

			const float DistToCody = (CymbalLocation - CymbalOwnerLocation).Size();
			const float NormalizedDistToCody = HazeAudio::NormalizeRTPC01(DistToCody, 0.f, 3950.f);
			CymbalHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Gadgets_Cymbal_Throw_Distance", NormalizedDistToCody);

			FVector CymbalVelo = (CymbalLocation - LastCymbalLocation).GetSafeNormal();
			FVector ToOwner = (CymbalOwnerLocation - CymbalLocation).GetSafeNormal();

			const float Dot = ToOwner.DotProduct(CymbalVelo);
			const float IsReturning = Dot > 0 ? 1.f : 0.f;

			if(IsReturning == 1.f && NormalizedDistToCody > 0.1f)
			{
				if(!CymbalHazeAkComp.EventInstanceIsPlaying(OnReturningEventInstance))
					OnReturningEventInstance = CymbalHazeAkComp.HazePostEvent(OnStartReturn);

				if(LastIsReturningValue != -1.f)
				{
					CymbalHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Gadgets_Cymbal_Direction", -1.f);	
					LastIsReturningValue = -1.f;
				}
			}

			LastCymbalLocation = CymbalLocation;
		}
	}
}