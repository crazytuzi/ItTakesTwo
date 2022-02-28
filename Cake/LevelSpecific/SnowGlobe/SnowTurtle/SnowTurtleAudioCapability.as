import Cake.LevelSpecific.Snowglobe.SnowTurtle.SnowTurtleBaby;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.AudioStatics;

class USnowTurtleAudioCapability : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent StartLoopingEvent;

	UPROPERTY()
	UAkAudioEvent StopLoopingEvent;

	UPROPERTY()
	UAkAudioEvent OnImpactEvent;

	UPROPERTY()
	int32 ImpactDistanceThreshold = 5;

	ASnowTurtleBaby SnowTurtle;
	UHazeAkComponent HazeAkComp;
	UHazeMovementComponent MoveComp;

	private float LastAngularVeloRtpc;
	private float LastVeloRtpc;

	private FVector TurtleCurrentLocation;
	private FVector TurtleLastLocation;
	private FVector LastDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowTurtle = Cast<ASnowTurtleBaby>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(SnowTurtle);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (SnowTurtle == nullptr)
        	return EHazeNetworkActivation::DontActivate;
		
		if (SnowTurtle.bCanMoveToNest)
        	return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;
			
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TurtleLastLocation = SnowTurtle.GetActorLocation();		
		LastDirection = SnowTurtle.GetActorLocation() - TurtleLastLocation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SnowTurtle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SnowTurtle.bCanMoveToNest)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (SnowTurtle.bIsSettledInNest)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HazeAkComp.HazePostEvent(StopLoopingEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioStart") == EActionStateStatus::Active)
			HazeAkComp.HazePostEvent(StartLoopingEvent);

		if(ConsumeAction(n"AudioStop") == EActionStateStatus::Active)
			HazeAkComp.HazePostEvent(StopLoopingEvent);
	
		const FVector CurrentVelo = MoveComp.Velocity;
		TurtleCurrentLocation = SnowTurtle.GetActorLocation();

		const float NormalizedTurtleVelo = HazeAudio::NormalizeRTPC01(CurrentVelo.Size(), 0.f, 2800.f);

		if(NormalizedTurtleVelo != LastVeloRtpc)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_SnowGlobe_Interactions_TurtleFamily_Shell_Glide_Velocity", NormalizedTurtleVelo);
			LastVeloRtpc = NormalizedTurtleVelo;
		}

		FVector OutImpactVeloVector;
		ConsumeAttribute(n"AudioOnCollisionHit", OutImpactVeloVector);
		if(OutImpactVeloVector != FVector::ZeroVector && HasMovedForImpact())
		{
			const float NormalizedImpactIntensity = HazeAudio::NormalizeRTPC01(OutImpactVeloVector.Size(), 0.f, 2000.f);
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_SnowGlobe_Interactions_TurtleFamily_Shell_Impact_Intensity", NormalizedImpactIntensity);
			HazeAkComp.HazePostEvent(OnImpactEvent);
		}				

		FVector Direction = TurtleCurrentLocation - TurtleLastLocation;				
		float Dot = 1 - FMath::Abs(Direction.DotProduct(LastDirection));
		float NormalizedAngularVelocity = HazeAudio::NormalizeRTPC01(FMath::Abs(Dot), 0.f, 4000.f);				

		if(NormalizedAngularVelocity != LastAngularVeloRtpc)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_SnowGlobe_Interactions_TurtleFamily_Shell_Glide_Angular_Velocity", NormalizedAngularVelocity);
			LastAngularVeloRtpc = NormalizedAngularVelocity;
		}	

		LastDirection = Direction;
		TurtleLastLocation = TurtleCurrentLocation;
	}	

	bool HasMovedForImpact()
	{
		float Dist = (TurtleCurrentLocation - TurtleLastLocation).Size();
		return  Dist >= ImpactDistanceThreshold;
	}
}