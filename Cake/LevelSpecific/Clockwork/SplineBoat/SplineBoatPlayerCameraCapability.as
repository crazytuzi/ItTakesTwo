import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerComponent;

class USplineBoatPlayerCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"SplineBoat");
	
	default CapabilityDebugCategory = n"GamePlay";	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;

	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;

	USplineBoatPlayerComponent SplineBoatPlayerComp;
	UHazeSplineFollowComponent SplineFollowComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	float NewLooKTime;
	float LookRate = 1.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraComp = UCameraComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		SplineBoatPlayerComp = USplineBoatPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (SplineFollowComp == nullptr)
		{
			SplineFollowComp = SplineBoatPlayerComp.SplineFollowComp;
		}
		else
		{
			if (!GetAttributeVector(AttributeVectorNames::CameraDirection).IsNearlyZero())
			{
				NewLooKTime = System::GameTimeInSeconds + LookRate;
			}
			else
			{
				CameraRotation(DeltaTime);
			}
		}
	}

	void CameraRotation(float DeltaTime)
	{
		if (NewLooKTime <= System::GameTimeInSeconds)
		{
			UHazeSplineFollowComponent CameraPositionSystem = SplineBoatPlayerComp.SplineFollowComp;
			FHazeSplineSystemPosition CameraLookPosition = CameraPositionSystem.Position;

			FVector CameraSplinePos;

			float RemainingMoveAmount = 0.f;

			if (!CameraLookPosition.Move(1300.f, RemainingMoveAmount))
				CameraSplinePos = CameraLookPosition.WorldLocation + (CameraLookPosition.WorldForwardVector * RemainingMoveAmount);
			else
				CameraSplinePos = CameraLookPosition.WorldLocation;

			CameraSplinePos += FVector(0,0,160.f);

			FVector PlayerCameraPosition = Player.ViewLocation;

			FVector LookDirection = CameraSplinePos - PlayerCameraPosition;

			FRotator CameraMakeRot = FRotator::MakeFromX(LookDirection);
			CameraMakeRot.Roll = 0.f;
			
			AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
			AcceleratedTargetRotation.AccelerateTo(CameraMakeRot, 2.8f, DeltaTime);
			CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
		}
		else
		{
			AcceleratedTargetRotation.SnapTo(FRotator(0));
		}

	}
}