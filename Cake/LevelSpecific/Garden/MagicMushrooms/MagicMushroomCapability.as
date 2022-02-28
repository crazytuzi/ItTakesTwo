import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.VOBanks.GardenGreenhouseVOBank;
class UMagicMushroomCapability : UHazeCapability
{
	UPROPERTY()
	UBlendSpace CodyBS;

	UPROPERTY()
	UBlendSpace MayBS;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY()
	UCurveFloat ScaleFloat;

	UPROPERTY()
	UGardenGreenhouseVOBank VOBank;

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	float TimeSinceStart;

	AHazePlayerCharacter Player;
	UHazeBaseMovementComponent Movecomp;
	FQuat DesiredLookRotation;                                                            

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Movecomp = Player.MovementComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"MagicMushroom") && Movecomp.CanCalculateMovement())
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
		else                                                                       
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"MagicMushroom"))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeSinceStart = 0;
		DesiredLookRotation = Player.ActorRotation.Quaternion();
		if (Player.IsCody())
		{
			Player.PlayBlendSpace(CodyBS);
		}
		else
		{
			Player.PlayBlendSpace(MayBS);
		}
		
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"Movement", this);
		FHazeCameraBlendSettings Blendsettings;
		Player.ApplyCameraSettings(CamSettings, Blendsettings, this);
		Player.BlockMovementSyncronization(this);

		if(Player.IsCody())
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenGreenhouseMagicMushroomsCody", Player.GetOtherPlayer());
		}
		else
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenGreenhouseMagicMushroomsMay", Player.GetOtherPlayer());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopBlendSpace();
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.UnblockMovementSyncronization(this);
		Player.SetActorRelativeScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float MovementMultiplier = 100;
		FHazeFrameMovement Movement = Movecomp.MakeFrameMovement(n"Hover");
		
		float Alpha = DistanceToFloor * 0.0015f;
		Alpha = FMath::Clamp(Alpha, 0.f,1.f);
		Alpha = 1 - Alpha;
		MovementMultiplier = FMath::Lerp(0.f, 250.f, Alpha);
		FVector DesiredMoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (DesiredMoveDirection.Size() > 0)
		{
			DesiredLookRotation = FQuat::Slerp(DesiredLookRotation, FRotator::MakeFromX(DesiredMoveDirection).Quaternion(), DeltaTime * 2);
		}
		
		FVector MoveDelta = FVector::UpVector * MovementMultiplier * DeltaTime;
		MoveDelta += DesiredMoveDirection * 3;
		Movement.SetRotation(DesiredLookRotation);

		Movement.OverrideStepDownHeight(0);
		Movement.ApplyDelta(MoveDelta);
		Movecomp.Move(Movement);

		TimeSinceStart += DeltaTime;
		
		Player.SetActorRelativeScale3D(FVector::OneVector * ScaleFloat.GetFloatValue(TimeSinceStart));
	}

	float GetDistanceToFloor() property
	{
		FVector StartPos = Player.ActorLocation;
		FVector Endpos = Player.ActorLocation + FVector::UpVector * - 1150;
		TArray<AActor> ActorsToIgnore;
		FHitResult HitResult;
		System::LineTraceSingle(StartPos,Endpos, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

		if (HitResult.bBlockingHit)
		{
			return HitResult.Location.Distance(Player.ActorLocation);
		}
		else
		{
			return -1;
		}
	}
}