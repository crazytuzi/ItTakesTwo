import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCorkBoardActor;

class USelfieImageMoveCapability : UHazeCapability
{	
	default CapabilityTags.Add(n"SelfieImageMoveCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	TArray<ASelfieCorkBoardActor> SelfieCorkBoardArray;

	ASelfieCorkBoardActor SelfieCorkBoard;
	
	ASelfieCameraImage Image;

	FVector TargetLocation;
	FRotator TargetRotation;

	float LocSpeed = 2300.f;
	float RotSpeed = 210.f;

	float DistFromTarget;

	FVector CurrentLoc;
	FRotator CurrentRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Image = Cast<ASelfieCameraImage>(Owner);
		GetAllActorsOfClass(SelfieCorkBoardArray);
		SelfieCorkBoard = SelfieCorkBoardArray[0]; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Image.SelfieImageMovementState == ESelfieImageMovementState::Moving)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Image.SelfieImageMovementState != ESelfieImageMovementState::Moving)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SelfieCorkBoard.SetNextImage(Image);

		TargetLocation = SelfieCorkBoard.GetImageTargetLocation();
		TargetRotation = SelfieCorkBoard.GetImageTargetRotation();
		Image.TargetCam = SelfieCorkBoard.GetCamera();

		DistFromTarget = (Image.ActorLocation - TargetLocation).Size();

		CurrentLoc = Image.ActorLocation;
		CurrentRot = Image.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SelfieCorkBoard.DeleteLastImage(Image);
		Image.MeshComp.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
		Image.SetActorRotation(TargetRotation);
		Image.EnableImageInspect();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector PreviousLoc = Image.ActorLocation;
		CurrentLoc = FMath::VInterpConstantTo(CurrentLoc, TargetLocation, DeltaTime, LocSpeed);
		CurrentRot = FMath::RInterpConstantTo(CurrentRot, TargetRotation, DeltaTime, RotSpeed);

		Image.SetActorLocationAndRotation(CurrentLoc, CurrentRot);

		Image.MeshComp.AddLocalRotation(FRotator(0.f, (-DistFromTarget / 1.65f) * DeltaTime, 0.f));

		if (PreviousLoc == CurrentLoc)
		{
			Image.SelfieImageMovementState = ESelfieImageMovementState::Still;
			Image.BP_ImageLandedOnBoard();
		}
	}
}