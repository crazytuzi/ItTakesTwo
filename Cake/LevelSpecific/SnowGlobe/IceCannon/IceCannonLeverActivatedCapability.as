import Cake.LevelSpecific.SnowGlobe.IceCannon.IceCannonActor;

class UIceCannonLeverActivatedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"IceCannonLeverActivatedCapability");
	default CapabilityTags.Add(n"IceCannon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AIceCannonActor IceCannon;

	bool bIsActive;
	bool bCanRun;

	int Stage;

	float StartRoll = 0.f;
	float TargetRoll = -45.f;

	FHazeAcceleratedFloat AccelRoll;

	FRotator InitialRotation;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		IceCannon = Cast<AIceCannonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IceCannon.bIceCannonCanCoolDown)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bIsActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bIsActive = true;

		bCanRun = false;

		Stage = 0;

		InitialRotation = IceCannon.MeshLever.RelativeRotation;

		FHazeAnimationDelegate BlendingOutDelegate;
		BlendingOutDelegate.BindUFunction(this, n"AnimationComplete");

		if (IceCannon.PlayerWhoTriggered == Game::May)
			IceCannon.PlayerWhoTriggered.PlaySlotAnimation(Animation = IceCannon.MayLeverSlap, bLoop = false, OnBlendingOut = BlendingOutDelegate);
		else
			IceCannon.PlayerWhoTriggered.PlaySlotAnimation(Animation = IceCannon.CodyLeverSlap, bLoop = false, OnBlendingOut = BlendingOutDelegate);

		IceCannon.PlayerWhoTriggered.CleanupCurrentMovementTrail();
		
		IceCannon.PlayerWhoTriggered.BlockCapabilities(CapabilityTags::Movement, this);

		System::SetTimer(this, n"InitiateMovements", 0.3f, false);
	}

	UFUNCTION()
	void InitiateMovements()
	{
		bCanRun = true;
	}

	UFUNCTION()
	void AnimationComplete()
	{
		IceCannon.PlayerWhoTriggered.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bCanRun)
			return;

		FRotator NewRot;

		if (Stage == 0)
		{
			AccelRoll.AccelerateTo(TargetRoll, 0.5f, DeltaTime);
			NewRot = InitialRotation + FRotator(0.f, 0.f, AccelRoll.Value);

			float Diff = AccelRoll.Value - TargetRoll;

			Diff = FMath::Abs(Diff);

			if (Diff <= 0.01f)
				Stage++;
		}
		else 
		{
			AccelRoll.AccelerateTo(StartRoll, 1.5f, DeltaTime);
			NewRot = InitialRotation + FRotator(0.f, 0.f, AccelRoll.Value);

			float Diff = AccelRoll.Value - StartRoll;

			Diff = FMath::Abs(Diff);

			if (Diff <= 0.05f)
				bIsActive = false;
		}

		IceCannon.MeshLever.SetRelativeRotation(NewRot);
	}	
}