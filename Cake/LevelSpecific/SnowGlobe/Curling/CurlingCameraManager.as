import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

enum ECurlingCamManagerState
{
	Inactive,
	Following,
	FinalShot 
};

class ACurlingCameraManager : AHazeActor
{
	ECurlingCamManagerState CamManagerState;
	
	// bool bHaveReset;

	UPROPERTY(Category = "Camera")
	AHazeCameraActor FollowCam;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(Category = "Camera")
	AHazeActor StartingLine;

	ACurlingStone InPlayCurlingStone;

	TArray<ACurlingStone> TargetStonesArray;

	AHazePlayerCharacter Player;
	
	UPROPERTY(meta = (MakeEditWidget))
	FVector FinalCamLoc;

	UPROPERTY(Category = "PlayerTarget")
	EHazePlayer TargetPlayer;

	FHazeAcceleratedRotator AcceleratedCamRotation;
	FHazeAcceleratedVector AcceleratedCamLocation;

	FVector ActualLocation;
	FVector ArenaForwardDirection;
	FVector PlayerCamReturnLoc;
	FRotator PlayerCamReturnRot;

	FVector StartingCameraLoc;
	FRotator StartingCameraRot;

	float ZValue;
	float DistanceFromOrigin;
	float SpeedPercentage;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CameraCapability;

	bool bNonControlledBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingCameraLoc = FollowCam.ActorLocation;
		StartingCameraRot = FollowCam.ActorRotation;

		if (TargetPlayer == EHazePlayer::May)
		{
			Player = Game::May;
			SetControlSide(Player);
		}
		else
		{
			Player = Game::Cody;
			SetControlSide(Player);
		}

		AddCapabilitySheet(CameraCapability);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (InPlayCurlingStone == nullptr)
			return;

		if (TargetStonesArray.Num() > 1)
		{
			FVector OldAverageLocation(0.f);
			int DivisionAmount = 0;

			for (ACurlingStone Stone : TargetStonesArray)
			{
				if (Stone != InPlayCurlingStone)
				{
					FVector DirToInPlay = InPlayCurlingStone.ActorLocation - ActorLocation;
					DirToInPlay.Normalize();

					FVector DirToThisStone = Stone.ActorLocation - ActorLocation;
					DirToThisStone.Normalize();

					float Dot = DirToInPlay.DotProduct(DirToThisStone);
					
					if (Dot >= 0.4f)
					{
						OldAverageLocation += Stone.ActorLocation; 
						DivisionAmount++;
					}
				}
			} 

			if (OldAverageLocation.Size() != 0)
			{
				OldAverageLocation /= DivisionAmount;
				FVector ToNewLocation = InPlayCurlingStone.ActorLocation - OldAverageLocation;
				ActualLocation = OldAverageLocation + (ToNewLocation * 0.66f);
			}
			else
			{
				ActualLocation = InPlayCurlingStone.ActorLocation;
			}
			
		}
		else if (TargetStonesArray.Num() == 1)
		{
			ActualLocation = TargetStonesArray[0].ActorLocation;
		}
	}

	void ResetFollowCamera()
	{
		AcceleratedCamLocation.SnapTo(Player.ViewLocation);
		AcceleratedCamRotation.SnapTo(Player.ViewRotation);
		FollowCam.SetActorLocation(Player.ViewLocation);
		FollowCam.SetActorRotation(Player.ViewRotation);
	}

	UFUNCTION()
	void ChangeCameraState(ECurlingCamManagerState InputCameraState)
	{
		CamManagerState = InputCameraState;
	}

	UFUNCTION()
	void SetBlockNonControlledCam(bool Value)
	{
		if (Value && !bNonControlledBlocked)
		{
			Player.BlockCapabilities(CameraTags::NonControlled, this);
			bNonControlledBlocked = true;
		}
		else if (!Value && bNonControlledBlocked)
		{
			Player.UnblockCapabilities(CameraTags::NonControlled, this);
			bNonControlledBlocked = false;
		}
	}
}