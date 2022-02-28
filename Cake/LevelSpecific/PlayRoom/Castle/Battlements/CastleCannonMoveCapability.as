import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;

class UCastleCannonMoveCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent ShooterComponent;
	ACastleCannon ActiveCannon;
	ACastleCannonMovementSpline CannonSpline;

	float DistanceAlongSpline;

	float MoveSpeedCurrent = 1000.f;
	float MoveSpeedMax = 3000.f;
	float MoveSpeedAcceleration = 500.f;
	float MoveSpeedDecceleration = 2000.f;



	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShooterComponent = UCastleCannonShooterComponent::GetOrCreate(Owner);
		ActiveCannon = ShooterComponent.ActiveCannon;
		CannonSpline = ActiveCannon.CannonSpline;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
    }	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ShooterComponent.ActiveCannon == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (ActiveCannon.DistanceAlongSplineSyncComp.HasControl())
			ActiveCannon.DistanceAlongSplineSyncComp.Value = ActiveCannon.DistanceAlongSpline;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		//FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		float MovementDelta = LeftStickInput.X * MoveSpeedCurrent * DeltaTime;

		if (ActiveCannon.DistanceAlongSplineSyncComp.HasControl())
		{
			ActiveCannon.DistanceAlongSplineSyncComp.Value = ActiveCannon.DistanceAlongSplineSyncComp.Value + MovementDelta;
			ActiveCannon.DistanceAlongSplineSyncComp.Value = FMath::Clamp(ActiveCannon.DistanceAlongSplineSyncComp.Value, 0, ActiveCannon.CannonSpline.Spline.GetSplineLength());
		}

		ActiveCannon.MoveCannonToDistanceAlongSpline();
	}

	void UpdateSpeed(float DeltaTime)
	{
		//FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		float MoveSpeedTarget = LeftStickInput.X * MoveSpeedMax;
		float MoveSpeedDelta = MoveSpeedTarget - MoveSpeedCurrent;

		if (MoveSpeedTarget > MoveSpeedCurrent)
		{

		}
		/*MoveSpeedCurrent += LeftStickInput.X * MoveSpeedAcceleration * DeltaTime;
		MoveSpeedCurrent = FMath::Clamp(MoveSpeedCurrent, -MoveSpeedMax, MoveSpeedMax);*/
	}

	void AddDecceleration(float DeltaTime)
	{
		/*FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		MoveSpeedCurrent -= (1 - LeftStickInput.X) * MoveSpeedDecceleration * DeltaTime;
		MoveSpeedCurrent = FMath::Clamp(MoveSpeedCurrent, -MoveSpeedMax, MoveSpeedMax);*/
	}

	void MoveCannon(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ShooterComponent.ActiveCannon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);

		if(IsActive())
		{
			FString DebugText = "";
			DebugText += "DistanceAlongSpline: " + DistanceAlongSpline + "\n";
			DebugText += "Move Input: " + LeftStickInput.X + "\n";		

			return DebugText;
		}

		return "Not Active";
	}
}