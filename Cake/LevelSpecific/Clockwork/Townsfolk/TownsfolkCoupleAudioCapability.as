import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkCouple;

class UTownsfolkCoupleAudioCapability : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent StartMovementLoopingEvent;

	UPROPERTY()
	UAkAudioEvent StopMovementLoopingEvent;	

	UPROPERTY()
	UAkAudioEvent HitBlockerEvent;

	ATownsfolkCouple CoupleOwner;
	UPrimitiveComponent TownsfolkCollider;
	UHazeAkComponent HazeAkComp;	

	private FVector LastPos;
	private float LastNormalizedSpeed;
	private float LastAngularVelo;

	private bool bAudioStoppedMoving = false;

	private FRotator LastRotation;

	private int32 MovementLoopInstancePlayingId;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CoupleOwner = Cast<ATownsfolkCouple>(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(CoupleOwner);
		HazeAkComp.SetStopWhenOwnerDestroyed(false);
		TownsfolkCollider = UPrimitiveComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioStartedMoving") == EActionStateStatus::Active)
			MovementLoopInstancePlayingId = HazeAkComp.HazePostEvent(StartMovementLoopingEvent).PlayingID;
		
		if(ConsumeAction(n"AudioStoppedAtBlocker") == EActionStateStatus::Active)
			HazeAkComp.HazePostEvent(HitBlockerEvent);

		if(ConsumeAction(n"AudioStoppedMoving") == EActionStateStatus::Active)
			bAudioStoppedMoving = true;

		const float Speed = (CoupleOwner.GetActorLocation() - LastPos).Size();
		const float NormalizedSpeed = HazeAudio::NormalizeRTPC01(Speed, 0.f, 12.f);
		const float AngularVelo = GetAngularVelocityValue();

		if(NormalizedSpeed == 0.f && bAudioStoppedMoving)
		{
			HazeAkComp.HazePostEvent(StopMovementLoopingEvent);	
			bAudioStoppedMoving = false;		
		}

		if(NormalizedSpeed != LastNormalizedSpeed)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Clockwork_Townsfolk_Couple_Speed", NormalizedSpeed);
			LastNormalizedSpeed = NormalizedSpeed;
		}

		if(AngularVelo != LastAngularVelo)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Clockwork_Townsfolk_Couple_AngularVelocity", AngularVelo);
			LastAngularVelo = AngularVelo;
		}		

		LastPos = CoupleOwner.GetActorLocation();
	}

	float GetAngularVelocityValue()
	{		
		float AngularVelo = TownsfolkCollider.GetPhysicsAngularVelocityInDegrees().Size();
		float NormalizedAngularVelocity = HazeAudio::NormalizeRTPC01(AngularVelo, 0.f, 200.f);

		return NormalizedAngularVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HazeAkComp.HazeStopEvent(MovementLoopInstancePlayingId, 1000.f);
	}
}