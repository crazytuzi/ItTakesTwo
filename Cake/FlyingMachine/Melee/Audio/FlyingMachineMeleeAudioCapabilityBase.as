import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;

enum EHazeMeleeAudioAction 
{	
	Crouch,
	MoveForwards,
	MoveBackwards,
	Jump,
	KickLight,
	KickHeavy,
	JumpKick,
	PunchLight,
	PunchHeavy,
	Haymaker,	
	Hazelnutdouken,
	Grab,
	Divekick,
	Kickflip,
	DodgeRoll,
	Land,
	Standup,
	Turn,
	Uppercut,
	HeadbuttCharge,
	OneTwo,
	LowSwipe,
	Knockback,
	TailSwipe,
	Taunt,
	ThrowFwd,
	ThrowBwd,
	PowerUp,
	Finisher,
	ThrowStart,
	KickLow,
	SpinJump
}

struct FMeleeAudioImpact
{
	UPROPERTY()
	UHazeMeleeImpactAsset ImpactAsset;

	UPROPERTY()
	UAkAudioEvent AudioEvent;
}

struct FMeleeAudioAction
{
	UPROPERTY()
	EHazeMeleeAudioAction ActionType;

	UPROPERTY()
	UAkAudioEvent AudioEvent;
}

class UFlyingMachineMeleeAudioCapabilityBase : UHazeCapability
{
	UPROPERTY(Category = "Audio Events")
	TArray<FMeleeAudioImpact> ImpactEvents;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DefaultImpactEvent;

	UPROPERTY(Category = "Audio Events")
	TArray<FMeleeAudioAction> ActionEvents;	

	bool bNeedsResetRTPC = false;
	float OnHitRtpcTimer = 0.f;
	const float OnHitRtpcWaitTime =  0.5f;
	bool bCanTriggerCrouchAudio = true;

	UHazeAkComponent HazeAkComp;
	UFlyingMachineMeleeComponent MeleeComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{			
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		MeleeComp = UFlyingMachineMeleeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleAudioNotify();
		HandleImpacts();
		//ResetOnHitRtpc(DeltaTime);

		float OutCanTriggerCrouchValue;
		if(ConsumeAttribute(n"CanTriggerCrouchAudio", OutCanTriggerCrouchValue))
			bCanTriggerCrouchAudio = true;
	}

	void HandleAudioNotify()
	{
		int UnconvertedActionType;

		if(ConsumeAttribute(n"MeleeAudio", UnconvertedActionType))
		{
			EHazeMeleeAudioAction Action = EHazeMeleeAudioAction(UnconvertedActionType);
			for(FMeleeAudioAction AudioAction : ActionEvents)
			{
				if(AudioAction.ActionType != Action)
					continue;

				if(AudioAction.ActionType == EHazeMeleeAudioAction::Crouch && !bCanTriggerCrouchAudio)
					break;

				HazeAkComp.HazePostEvent(AudioAction.AudioEvent);

				if(AudioAction.ActionType == EHazeMeleeAudioAction::Crouch)
					bCanTriggerCrouchAudio = false;

				break;
			}
		} 	
	}	

	void HandleImpacts()
	{
		UObject RawAsset;

		if(ConsumeAttribute(n"PerformedHit", RawAsset))
		{
			bool bFoundEvent = false;
			auto ImpactAsset = Cast<UHazeMeleeImpactAsset>(RawAsset);

			for(FMeleeAudioImpact AudioImpact : ImpactEvents)
			{
				if(AudioImpact.ImpactAsset != ImpactAsset)
					continue;

				HazeAkComp.HazePostEvent(AudioImpact.AudioEvent);
				bFoundEvent = true;
				break;
			}

			if(!bFoundEvent)
				HazeAkComp.HazePostEvent(DefaultImpactEvent);			
		}

		if(ConsumeAttribute(n"WasHit", RawAsset))
		{
			HazeAkComp.SetRTPCValue("Rtpc_Melee_SquirrelFight_OnHit", 1.f, 700.f);
			bNeedsResetRTPC = true;
			auto ImpactAsset = Cast<UHazeMeleeImpactAsset>(RawAsset);

			if(ImpactAsset.ImpactTag == n"Hanuten")
			{
				HazeAkComp.HazePostEvent(DefaultImpactEvent);
			}
		}

	}

	void ResetOnHitRtpc(float DeltaSeconds)
	{
		if(!bNeedsResetRTPC)
			return;
		
		OnHitRtpcTimer += DeltaSeconds;

		if(OnHitRtpcTimer < OnHitRtpcWaitTime)
			return;

		HazeAkComp.SetRTPCValue("Rtpc_Melee_SquirrelFight_OnHit", 0.f, 500.f);
		OnHitRtpcTimer = 0.f;
		bNeedsResetRTPC = false;		
	}
	
}

