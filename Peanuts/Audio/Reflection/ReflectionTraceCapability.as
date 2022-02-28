import void Subscribe(UReflectionTraceCapability) from "Peanuts.Audio.Reflection.ReflectionTraceStatics";
import void Unsubscribe(UReflectionTraceCapability) from "Peanuts.Audio.Reflection.ReflectionTraceStatics";
import bool SetDelayParameterRanges(FReflectionTraceValues&, EEnvironmentType) from "Peanuts.Audio.Reflection.ReflectionTraceStatics";
import Vino.Audio.Capabilities.AudioTags;
import Peanuts.Audio.Reflection.ReflectionTraceComponent;

struct FTraceData
{	
	FHitResult HitResult;
	bool bIsUpdated = false;
}

struct FTraceReflectionData
{
	FVector Location;
	FVector Direction;

	float TraceLength;
}

enum EReflectionDirection
{
	FrontLeft = 0,
	FrontRight,

	NumOfDirections
}

class UReflectionTraceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Audio");
	default CapabilityTags.Add(AudioTags::PlayerReflectionTracing);
	default CapabilityTags.Add(AudioTags::PlayerReflectionTrace);
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	UReflectionTraceComponent TraceComponent;
	UHazeListenerComponent Listener;
	UPlayerHazeAkComponent PlayerHazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TraceComponent = UReflectionTraceComponent::Get(Owner);
		Listener = UHazeListenerComponent::Get(Owner);
		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerHazeAkComp = PlayerOwner.PlayerHazeAkComp;

		if (TraceComponent.FrontLeftSendData.TraceDirectionAngles == FVector::ZeroVector)
			TraceComponent.FrontLeftSendData.TraceDirectionAngles = FVector(0,0,-45);

		if (TraceComponent.FrontRightSendData.TraceDirectionAngles == FVector::ZeroVector)
			TraceComponent.FrontRightSendData.TraceDirectionAngles = FVector(0,0,45);

		TraceComponent.FrontLeftSendData.TraceDirection = 
			GetTraceDirectionFromAngle(TraceComponent.FrontLeftSendData.TraceDirectionAngles);
		TraceComponent.FrontRightSendData.TraceDirection = 
			GetTraceDirectionFromAngle(TraceComponent.FrontRightSendData.TraceDirectionAngles);
	}

	FVector GetTraceDirectionFromAngle(FVector DirectionAngles) 
	{
		FVector Forward = FVector::ForwardVector;

		FQuat QuatX(FVector::ForwardVector, DirectionAngles.X * DEG_TO_RAD);
		Forward = QuatX.RotateVector(Forward);

		FQuat QuatY(FVector::RightVector, DirectionAngles.Y * DEG_TO_RAD);
		Forward = QuatY.RotateVector(Forward);

		FQuat QuatZ(FVector::UpVector, DirectionAngles.Z * DEG_TO_RAD);
		Forward = QuatZ.RotateVector(Forward);

		return Forward;
	}

	FReflectionTraceData& GetReflectionTraceData(int Index)
	{
		switch(EReflectionDirection(Index))
		{
			case EReflectionDirection::FrontLeft:
			return TraceComponent.FrontLeftSendData;
			case EReflectionDirection::FrontRight:
			return TraceComponent.FrontRightSendData;
		}

		return TraceComponent.FrontLeftSendData;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Subscribe(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Unsubscribe(this);
		ResetTraceComponent();
	}

	void ResetTraceComponent()
	{
		TraceComponent.OnCapabilityDisabled();
	}

	int NumOfTracesAndDirections()
	{
		return EReflectionDirection::NumOfDirections;
	}
	
	FVector GetLocation() 
	{
		return Listener.GetWorldLocation();
	}

	FVector GetTraceDirection(int Index) 
	{
		FVector Direction = GetReflectionTraceData(Index).TraceDirection;
		FRotator Rotator = Listener.GetWorldRotation();
		if (Direction.Z == 0)
		{
			FVector Forward = Rotator.ForwardVector;
			Forward.Z = 0;
			Rotator = Forward.Rotation();
		}

		FVector RotatedVector = Rotator.RotateVector(Direction);

		return RotatedVector;	
	}

	UFUNCTION()
	void OnTraceUpdate(int Index, FHitResult& HitResult)
	{
		// NOTE: TBD if required.
		// FVector NewLocation = HitResult.Location;
		// TraceComponent.UpdateTraceComponentLocation(Directions[Index], NewLocation);
		
		TraceComponent.UpdateReflectionSendData(
			Cast<AAmbientZone>(PlayerHazeAkComp.GetPrioReverbZone()),
		 	GetReflectionTraceData(Index), HitResult, Index);
	}

	UFUNCTION()
	void OnGetTraceData(int Index, FTraceReflectionData& TraceData)
	{
		FTraceReflectionData Data;
		Data.Location = GetLocation();
		Data.Direction = GetTraceDirection(Index);
		// TODO (GK) - Make a proper check for this.
		Data.TraceLength =  (GetReflectionTraceData(Index)).CurrentTraceValues.MaxTraceDistance;
		if (Data.TraceLength == 0)
			Data.TraceLength = TraceComponent.MaxTraceDistance;
		TraceData = Data;
	}
}