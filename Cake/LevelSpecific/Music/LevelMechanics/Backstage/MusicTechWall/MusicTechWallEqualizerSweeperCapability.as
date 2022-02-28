// import Vino.Movement.Components.MovementComponent;
// import Cake.LevelSpecific.Music.Singing.SingingComponent;
// import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallEqualizerSweeper;

// class UEqualizerSweeperCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 50;

// 	AHazePlayerCharacter Player;
// 	UHazeMovementComponent MoveComp;
// 	USingingComponent SingingComp;
// 	AMusicTechWallEqualizerSweeper EqualizerSweeper;

// 	TArray<AMusicTechWallEqualizerSweeper> EqualizerSweeperArray;

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
// 		if (!IsActioning(n"EqualizerSweeper"))
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
// 			AMusicTechWallEqualizerSweeper Sweeper = Cast<AMusicTechWallEqualizerSweeper>(ActivationComp.Owner); 
// 			if (Sweeper != nullptr)
// 				EqualizerSweeperArray.Add(Sweeper);
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

// 		for (AMusicTechWallEqualizerSweeper Sweeper : EqualizerSweeperArray)
// 		{
// 			Sweeper.UpdateInput(LeftInput);	
// 		}
// 	}
// }