import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechKnobs;

class UMusicTechCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicTechCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"MusicTechCapability";
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMusicTechKnobs MusicTechKnobs;

	FVector2D LeftInput;
	FVector2D RightInput;

	FVector2D RotatedPreviousLeftInput;
	FVector2D RotatedPreviousRightInput;

	float LeftRotationRate = 0.f;
	float RightRotationRate = 0.f;

	float LeftRotationRateInterp = 0.f;
	float RightRotationRateInterp = 0.f;

	FRotator LeftRot;
	FRotator RightRot;

	UHazeSmoothSyncVectorComponent LeftInputSync;
	UHazeSmoothSyncVectorComponent RightInputSync;
	UHazeSmoothSyncFloatComponent LeftRotationSync;
	UHazeSmoothSyncFloatComponent RightRotationSync;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		LeftInputSync = UHazeSmoothSyncVectorComponent::GetOrCreate(Owner, n"LeftInputSync");
		RightInputSync = UHazeSmoothSyncVectorComponent::GetOrCreate(Owner, n"RightInputSync");
		LeftRotationSync = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"LeftRotationSync");
		RightRotationSync = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"RightRotationSync");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"ControllingMusicTechKnob"))
			return EHazeNetworkActivation::DontActivate;

		if(GetAttributeObject(n"MusicKnobActor") == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ControllingMusicTechKnob"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UObject KnobsTemp;
		if (ConsumeAttribute(n"MusicKnobActor", KnobsTemp))
		{
			AMusicTechKnobs TempTechKnobs = Cast<AMusicTechKnobs>(KnobsTemp);
			ActivationParams.AddObject(n"MusicKnobActor", TempTechKnobs);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MusicTechKnobs = Cast<AMusicTechKnobs>(ActivationParams.GetObject(n"MusicKnobActor"));
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::LevelSpecific, this);
		Owner.SetActorRotation(MusicTechKnobs.TeleportLocationActor.ActorRotation);
		Owner.SetActorLocation(MusicTechKnobs.TeleportLocationActor.ActorLocation);
		Player.AddLocomotionFeature(MusicTechKnobs.CodyFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::LevelSpecific, this);
		Player.RemoveLocomotionFeature(MusicTechKnobs.CodyFeature);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"CodyTechWallKnobs";
		Player.RequestLocomotion(AnimationRequest);

		if(HasControl())
		{	
			FVector2D Inputs = CalculateStickRotation(DeltaTime);		
			MusicTechKnobs.UpdateInputs(Inputs);		

			// Send the stick input
			LeftInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			RightInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
			const FVector LeftStickInput = FVector(LeftInput.X, LeftInput.Y, 0.f);
			const FVector RightStickInput = FVector(RightInput.X, RightInput.Y, 0.f);

			auto InputComp = UHazeInputComponent::Get(Player);
			auto ControllerType = InputComp.GetControllerType();
			if (ControllerType == EHazePlayerControllerType::Keyboard)
			{
				LeftRot.Yaw +=  ((LeftRotationRateInterp * -4.f) * 400.f) * DeltaTime;
				LeftInputSync.Value = LeftRot.Vector();
				RightRot.Yaw += ((RightRotationRateInterp * -4.f) * 400.f) * DeltaTime;
				RightInputSync.Value = RightRot.Vector();
			} else
			{
				LeftInputSync.Value = LeftStickInput;
				RightInputSync.Value = RightStickInput;
			}
			
			Player.SetAnimVectorParam(n"LeftStickInput", LeftInputSync.Value);
			Player.SetAnimVectorParam(n"RightStickInput", RightInputSync.Value);

			LeftRotationSync.Value = LeftRotationRateInterp;
			RightRotationSync.Value = RightRotationRateInterp;	
		}
		else
		{		
			MusicTechKnobs.UpdateInputs(FVector2D(LeftRotationSync.Value, RightRotationSync.Value));

			//PrintToScreenScaled(""+LeftInput.Size());
			//RotatedPreviousLeftInput = FVector2D(LeftInputSync.Value.Y, -LeftInputSync.Value.X);
			//RotatedPreviousRightInput = FVector2D(RightInputSync.Value.Y, -RightInputSync.Value.X);
		}

	}

	FVector2D CalculateStickRotation(float DeltaTime)
	{
		auto InputComp = UHazeInputComponent::Get(Player);
		auto ControllerType = InputComp.GetControllerType();
		if (ControllerType == EHazePlayerControllerType::Keyboard)
		{
			const FVector2D InputRawStick = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			float InputX = InputRawStick.X;

			// Move left knob with A and D if a keyboard is used
			if (InputX <= -0.9f)
				LeftRotationRate = -0.25f;
			else if (InputX >= 0.9f)
				LeftRotationRate = 0.25f;
			else
				LeftRotationRate = 0.f;

			// Move right knob with LMB and RMB if a keyboard is used
			if (IsActioning(ActionNames::PrimaryLevelAbility))
				RightRotationRate = -0.25f;
			else if (IsActioning(ActionNames::SecondaryLevelAbility))
				RightRotationRate = 0.25f;
			else
				RightRotationRate = 0.f;
			
			LeftRotationRateInterp = FMath::FInterpTo(LeftRotationRateInterp, LeftRotationRate, DeltaTime, 8.f);
			RightRotationRateInterp = FMath::FInterpTo(RightRotationRateInterp, RightRotationRate, DeltaTime, 8.f);
			
			return FVector2D(LeftRotationRateInterp, RightRotationRateInterp);
		}

		LeftInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		RightInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		
		LeftRotationRate = RotatedPreviousLeftInput.DotProduct(LeftInput);
		LeftRotationRate = FMath::Max(LeftRotationRate, -0.25f);
		LeftRotationRate = FMath::Min(LeftRotationRate, 0.25f);
		
		RightRotationRate = RotatedPreviousRightInput.DotProduct(RightInput);
		RightRotationRate = FMath::Max(RightRotationRate, -0.25f);
		RightRotationRate = FMath::Min(RightRotationRate, 0.25f);
		
		// Rotating previous input vector 90°
		RotatedPreviousLeftInput = FVector2D(LeftInput.Y, -LeftInput.X);
		RotatedPreviousRightInput = FVector2D(RightInput.Y, -RightInput.X);

		LeftRotationRateInterp = FMath::FInterpTo(LeftRotationRateInterp, LeftRotationRate, DeltaTime, 8.f);
		RightRotationRateInterp = FMath::FInterpTo(RightRotationRateInterp, RightRotationRate, DeltaTime, 8.f);

		return FVector2D(LeftRotationRateInterp, RightRotationRateInterp);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(LeftInputSync != nullptr)
			LeftInputSync.DestroyComponent(Owner);

		if(RightInputSync != nullptr)
			RightInputSync.DestroyComponent(Owner);
	}
}
