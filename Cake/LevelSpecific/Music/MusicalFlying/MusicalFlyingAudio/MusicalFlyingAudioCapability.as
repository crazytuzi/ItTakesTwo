import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.Singing.SingingAudio.SingingAudioComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UMusicalFlyingAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UMusicalFlyingComponent MusicFlyComp;
	USingingAudioComponent SingAudioComponent;
	UCymbalComponent CymbalComp;

	UPROPERTY()
	UAkAudioEvent OnStartFlyingEvent;

	UPROPERTY()
	UAkAudioEvent OnStopFlyingEvent;

	UPROPERTY()
	UAkAudioEvent OnBoostEvent;

	UPROPERTY()
	UAkAudioEvent OnBarrelRollEvent;

	FVector LastLocation;
	FRotator LastRotation;

	UPROPERTY(NotEditable)
	FString TiltRtpc = "Rtpc_Gameplay_Vehicles_Jetpack_AngularVelo";

	UPROPERTY(NotEditable)
	FString AngularVeloRtpc = "Rtpc_Gameplay_Vehicles_Jetpack_Tilt";

	private float LastTiltValue = 0.f;
	private float LastAngularVeloValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		MusicFlyComp = UMusicalFlyingComponent::Get(Player);

		if(Player.IsMay())
			SingAudioComponent = USingingAudioComponent::Get(Player);
		else
			CymbalComp = UCymbalComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MusicFlyComp.bIsFlying)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.PlayerHazeAkComp.HazePostEvent(OnStartFlyingEvent);

		if(SingAudioComponent != nullptr)
			SingAudioComponent.bActivateOnFlying = true;

		if(CymbalComp != nullptr)
			CymbalComp.bCymbalAudioOnFlying = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioStartBoost") == EActionStateStatus::Active)
		{
			Player.PlayerHazeAkComp.HazePostEvent(OnBoostEvent);
		}

		float Tilt = 0.f;
		float AngularVelo = 0.f;

		GetFlyingMovementValues(Tilt, AngularVelo);

		if(Tilt != LastTiltValue)
		{
			Player.PlayerHazeAkComp.SetRTPCValue(TiltRtpc, Tilt);
			LastTiltValue = Tilt;
		}

		if(AngularVelo != LastAngularVeloValue)
		{
			Player.PlayerHazeAkComp.SetRTPCValue(AngularVeloRtpc, AngularVelo);
			LastAngularVeloValue = AngularVelo;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MusicFlyComp.bIsFlying && Player.MovementComponent.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.PlayerHazeAkComp.HazePostEvent(OnStopFlyingEvent);

		if(SingAudioComponent != nullptr)
			SingAudioComponent.bActivateOnFlying = false;

		if(CymbalComp != nullptr)
			CymbalComp.bCymbalAudioOnFlying = false;
	}

	void GetFlyingMovementValues(float& OutTilt, float& OutAngularVelo)
	{
		FVector WorldUp = MoveComp.WorldUp.GetSafeNormal();
		FVector CurrentLocation = Player.GetActorCenterLocation();

		FVector ActorForward = Player.GetActorForwardVector().GetSafeNormal();
		FVector Velo = CurrentLocation - LastLocation;

		FRotator RotationDelta = Player.GetActorRotation() - LastRotation;
		const float CalcedTilt = Velo.GetSafeNormal().DotProduct(WorldUp);
		OutTilt	= !MusicFlyComp.bIsHovering ? CalcedTilt : 0.f;

		FVector CurrentForward = Player.GetActorForwardVector();		
		const float CalctedAngularVelo = HazeAudio::NormalizeRTPC01(FMath::Abs(RotationDelta.Yaw), 0.f, 6.f);	
		OutAngularVelo = !MusicFlyComp.bIsHovering ? CalctedAngularVelo : 0.f;
	
		LastLocation = CurrentLocation;
		LastRotation = Player.GetActorRotation();
	}
}