import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneBodyWiggleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;

	AMurderMicrophone Snake;
	UMurderMicrophoneSettings Settings;

	float WiggleSpeedCurrent = 0.0f;
	float WiggleSpeedTarget = 0.0f;
	float SpeedModifierCurrent = 0.0f;

	bool bWiggleSpeedTransition = false;

	float LastWiggleSpeed = 0.0f;
	float PulseValue = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Snake.bEnableBodyWiggle)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bWiggleSpeedTransition = false;
		WiggleSpeedTarget = Settings.WiggleSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LastWiggleSpeed != Settings.WiggleSpeed && !bWiggleSpeedTransition && PulseValue > 0.0f)
		{
			bWiggleSpeedTransition = true;
			WiggleSpeedTarget = 0.0f;
		}
		
		WiggleSpeedCurrent = FMath::FInterpTo(WiggleSpeedCurrent, WiggleSpeedTarget, DeltaTime, 1.0f);
		SpeedModifierCurrent = FMath::FInterpTo(SpeedModifierCurrent, Settings.WiggleLength, DeltaTime, 5.0f);
		double Time = double(System::GameTimeInSeconds);

		if(bWiggleSpeedTransition)
		{
			PulseValue = FMath::FInterpConstantTo(PulseValue, 0.0f, DeltaTime, 1.75f);
		}
		else
		{
			PulseValue = MakePulsatingValue(Time, Settings.WiggleSpeed);
		}

		if(bWiggleSpeedTransition && FMath::Abs(PulseValue) <= 0.01f)
		{
			WiggleSpeedCurrent = 0.0f;
			bWiggleSpeedTransition = false;
			WiggleSpeedTarget = Settings.WiggleSpeed;
		}

		
		//const float PulseValue = (FMath::MakePulsatingValue(Time, WiggleSpeedCurrent) * 2.0f) - 1.0f;
		//PrintToScreen("PulseValue " + PulseValue);
		//PrintToScreen("WiggleSpeedCurrent " + WiggleSpeedCurrent);
		FVector Wiggle = Snake.HeadOffset.RightVector * PulseValue * (SpeedModifierCurrent * Snake.WiggleLengthModifier);
		Snake.WiggleOffset = FMath::VInterpTo(Snake.WiggleOffset, Wiggle, DeltaTime, 5.0f);

		LastWiggleSpeed = Settings.WiggleSpeed;
	}

	float MakePulsatingValue( const double InCurrentTime, const float InPulsesPerSecond, const float InPhase = 0.0f )
	{
		return 1.0f * FMath::Sin( ( ( 0.25f + InPhase ) * PI * 2.0f ) + ( float(InCurrentTime) * PI * 2.0f ) * InPulsesPerSecond );
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Snake.bEnableBodyWiggle)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
