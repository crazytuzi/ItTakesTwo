// import Vino.Movement.Components.MovementComponent;
// import Cake.LevelSpecific.Music.Singing.SingingComponent;
// import Cake.LevelSpecific.Music.LevelMechanics.AnalogTapeRecorder;

// class UAnalogTapeRecorderCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 50;

// 	AHazePlayerCharacter Player;
// 	UHazeMovementComponent MoveComp;
// 	USingingComponent SingingComp;
// 	AAnalogTapeRecorder TapeRecorder;

// 	TArray<AAnalogTapeRecorder> TapeRecorderArray;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
// 		SingingComp = USingingComponent::GetOrCreate(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (!IsActioning(n"AnalogTapeRecorder"))
//         	return EHazeNetworkActivation::DontActivate;
        
//         return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (SingingComp.CurrentInstrumentCompArray.Num() <= 0)
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if (!SingingComp.bInstrumentActive)
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		for (UInstrumentActivationComponent ActivationComp : SingingComp.CurrentInstrumentCompArray)
// 		{
// 			AAnalogTapeRecorder Recorder = Cast<AAnalogTapeRecorder>(ActivationComp.Owner); 
// 			if (Recorder != nullptr)
// 				TapeRecorderArray.Add(Recorder);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		FVector2D LeftInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
// 		FVector2D RightInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

// 		for (AAnalogTapeRecorder Recorder : TapeRecorderArray)
// 		{
// 			Recorder.UpdateInput(LeftInput, RightInput);	
// 		}
// 	}
// }