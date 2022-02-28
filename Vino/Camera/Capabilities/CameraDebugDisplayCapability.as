import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraSpringArmComponent;

// Capability added by debug menu when you want debug information drawn about cameras
class UCameraDebugDisplayCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CameraDebugInfo");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::LastDemotable;

	UCameraUserComponent User;
	AHazePlayerCharacter Player;
	UHazeCameraComponent PreviousActiveCamera = nullptr;
	bool bWasHazeDebug = false;
	FVector PreviousViewLocation;
	FRotator PreviousViewRotation;
	FVector PreviousSpringArmPivotLocation;
	int ViewLogIgnoreCount = 0;
	int OwnerLogIgnoreCount = 0;
	int SpringarmPivotLogIgnoreCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		User = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkActivation::DontActivate;

		if (!User.HasDebugDisplayFlags())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!User.HasDebugDisplayFlags())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PreviousViewRotation = Player.GetPlayerViewRotation();
		PreviousViewLocation = Player.GetPlayerViewLocation();
		UCameraSpringArmComponent SpringArm = Cast<UCameraSpringArmComponent>(User.GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent>(UCameraSpringArmComponent::StaticClass())));
		if (SpringArm != nullptr)
			PreviousSpringArmPivotLocation = SpringArm.PreviousPivotLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeCameraComponent CurCam = User.GetCurrentCamera();
		FVector ViewLoc = Player.GetPlayerViewLocation();
		FRotator ViewRot = Player.GetPlayerViewRotation();
		UCameraSpringArmComponent SpringArm = Cast<UCameraSpringArmComponent>(User.GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent>(UCameraSpringArmComponent::StaticClass())));
		FVector SpringarmPivotLoc = (SpringArm != nullptr) ? SpringArm.PreviousPivotLocation : PreviousSpringArmPivotLocation;

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::View))
		{
			// View information
			float FOV = Player.GetPlayerViewFOV();
			FVector ViewVel = (DeltaTime > 0.f) ? (ViewLoc - PreviousViewLocation) / DeltaTime : FVector::ZeroVector; 
			float ViewSpeed = ViewVel.Size();
			FRotator ViewRotVel = (DeltaTime > 0.f) ? (ViewRot - PreviousViewRotation) * (1.f / DeltaTime) : FRotator::ZeroRotator; 
			float ViewRotSpeed = ViewRotVel.Euler().Size();
			FString ViewDesc = Player.GetName() + " View velocity: " + ViewVel + " (" + ViewSpeed + ") Angular velocity: " + ViewRotVel + " (" + ViewRotSpeed + ") ViewLoc: " + ViewLoc + " ViewRot: " + ViewRot + " FOV: " + FOV + " DeltaTime: " + DeltaTime;
			FString IgnoredDesc = Player.GetName() + " had " + ViewLogIgnoreCount + " previous ticks of zero view velocity.";
			PrintDebugInfo(ViewDesc, ViewVel.IsNearlyZero(0.1f) && ViewRotVel.IsNearlyZero(0.1f), IgnoredDesc, ViewLogIgnoreCount);
		}

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::Owner))
		{
			AActor CamOwner = CurCam.GetOwner();
			AHazeActor HazeOwner = Cast<AHazeActor>(CamOwner);
			FVector Vel = CamOwner.GetActorVelocity();
			FVector ActualVel = (HazeOwner != nullptr) ? HazeOwner.GetActualVelocity() : Vel;
			FString OwnerDesc = CamOwner.GetName() + " Velocity: " + Vel + " (" + Vel.Size() + ") Actual: " + ActualVel + " (" + ActualVel.Size() + ") DeltaTime: " + DeltaTime;
			FString IgnoreDesc = CamOwner.GetName() + " had " + OwnerLogIgnoreCount + " previous ticks of zero velocity.";
			PrintDebugInfo(OwnerDesc, Vel.IsNearlyZero(0.1f) && ActualVel.IsNearlyZero(0.1f), IgnoreDesc, OwnerLogIgnoreCount);
		}

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::SpringArmPivot))
		{
			if (SpringArm != nullptr)
			{
				System::DrawDebugPoint(SpringarmPivotLoc, 10.f, FLinearColor::DPink);
				System::DrawDebugLine(SpringarmPivotLoc, SpringarmPivotLoc + FVector(0.f,0.f,400.f), FLinearColor::Yellow);

				FVector SpringarmVel = (DeltaTime > 0.f) ? (SpringarmPivotLoc - PreviousSpringArmPivotLocation) / DeltaTime : FVector::ZeroVector;
				FString Desc = SpringArm.Owner.GetName() + " springarm velocity: " + SpringarmVel + " (" + SpringarmVel.Size() + ") DeltaTime: " + DeltaTime;
				FString IgnoreDesc = SpringArm.Owner.GetName() + " had " + SpringarmPivotLogIgnoreCount + " previous ticks of zero velocity.";
				PrintDebugInfo(Desc, SpringarmVel.IsNearlyZero(0.1f), IgnoreDesc, SpringarmPivotLogIgnoreCount);
			}
		}

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::Blend))
		{
			FVector ViewDir = ViewRot.Vector();
			System::DrawDebugPoint(ViewLoc, 10.f, FLinearColor::Purple);
			System::DrawDebugArrow(ViewLoc, ViewLoc + ViewDir * 20.f, 5.f, FLinearColor::Purple, 0.f, 1.f);
			System::DrawDebugCoordinateSystem(ViewLoc + ViewDir * 20.f, ViewRot, 20.f, 0, 1);				

			UHazeCameraViewPoint ViewPoint = User.GetCameraViewPoint();
			TArray<FHazeCameraBlendFraction> CameraBlends;
			ViewPoint.GetCurrentCameraBlends(CameraBlends);
			if (CameraBlends.Num() > 1)
			{
				FLinearColor Color = FLinearColor::White;
				FVector ToLoc = CameraBlends[0].Camera.ViewLocation;
				FRotator ToRot = CameraBlends[0].Camera.ViewRotation;
				System::DrawDebugArrow(ToLoc, ToLoc + ToRot.Vector() * 10.f, 3.f, Color, 0.f, 1.f);
				System::DrawDebugPoint(ToLoc, 7.f, Color);
				System::DrawDebugCoordinateSystem(ToLoc - ToRot.Vector() * 10.f, ToRot, 10.f, 0, 1);				
				for (int i = 1; i < CameraBlends.Num(); i++)
				{
					FVector FromLoc = CameraBlends[i].BackUpview.Location;
					FRotator FromRot = CameraBlends[i].BackUpview.Rotation;	
					if (CameraBlends[i].Camera != nullptr)
					{
						FromLoc = CameraBlends[i].Camera.ViewLocation;	
						FromRot = CameraBlends[i].Camera.ViewRotation;	
					}
					System::DrawDebugLine(FromLoc, ToLoc, Color, 0.f, 2.f);
					Color *= 0.5f;
					System::DrawDebugArrow(FromLoc, FromLoc + FromRot.Vector() * 10.f, 3.f, Color, 0.f, 1.f);
					System::DrawDebugPoint(FromLoc, 7.f, (CameraBlends[i].Camera != nullptr) ? Color : FLinearColor::Red);
					float Size = 10.f - (i * 2.f);
					System::DrawDebugCoordinateSystem(FromLoc - FromRot.Vector() * (10.f + Size), FromRot, Size, 0, Size * 0.1f);
					ToLoc = FromLoc;
				}
			}
		}

#if EDITOR
		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::HazeDebugBool))
		{
			if (User.CurrentCamera != nullptr)
				User.CurrentCamera.bHazeEditorOnlyDebugBool = true;
			if ((PreviousActiveCamera != nullptr) && (User.CurrentCamera != PreviousActiveCamera))
				PreviousActiveCamera.bHazeEditorOnlyDebugBool = false;
		}
		else if (bWasHazeDebug && (PreviousActiveCamera != nullptr))
		{
			PreviousActiveCamera.bHazeEditorOnlyDebugBool = false;
		}
#endif

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::CurrentCamera))
		{
			if (User.CurrentCamera != nullptr)
			{
				FVector Vel = User.CurrentCamera.ViewVelocity;
				PrintToScreenScaled("    Speed: " + Vel.Size() + " (" + Vel + ")");
				PrintToScreenScaled("Current camera: " + User.CurrentCamera.Owner.Name);
			}
		}

		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::BlendOutBehaviour))
		{
			UHazeCameraViewPoint ViewPoint = User.GetCameraViewPoint();
			TArray<FHazeCameraBlendFraction> CameraBlends;
			ViewPoint.GetCurrentCameraBlends(CameraBlends);
			for (int i = CameraBlends.Num() - 1; i >= 0; i--)
			{
				UHazeCameraComponent Cam = CameraBlends[i].Camera;
				if (!System::IsValid(Cam))
					PrintToScreenScaled("Blending out DESTROYED camera");
				else if (Cam.GetCameraState() == EHazeCameraState::Active)
					PrintToScreenScaled("Current  " + Cam.Owner.GetName() + ": " + Cam.BlendOutBehaviour);
				else
					PrintToScreenScaled("Blending out " + Cam.Owner.GetName() + ": " + Cam.BlendOutBehaviour);
			}
		}

		bWasHazeDebug = User.ShouldDebugDisplay(ECameraDebugDisplayType::HazeDebugBool);
		PreviousActiveCamera = User.CurrentCamera;
		PreviousViewLocation = ViewLoc;
		PreviousViewRotation = ViewRot;
		PreviousSpringArmPivotLocation = SpringarmPivotLoc;
	}

	void PrintDebugInfo(const FString& Description, bool bIgnoreAfterFirst, const FString& IgnoreDesc, int& InOutIgnoredCount)
	{
		if (bIgnoreAfterFirst && (InOutIgnoredCount > 0))
		{
			PrintToScreen(Description); // Don't spam log
		}
		else
		{
			if (InOutIgnoredCount > 0)
				Print(IgnoreDesc);
			Print(Description);
		}
		if (bIgnoreAfterFirst)
			InOutIgnoredCount++;
		else
			InOutIgnoredCount = 0;
	}
}