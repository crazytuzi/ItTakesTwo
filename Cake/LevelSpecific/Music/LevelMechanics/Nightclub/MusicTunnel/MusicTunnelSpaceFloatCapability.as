import Peanuts.Animation.Features.Tree.LocomotionFeatureFireFlies;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelSpaceFloatManager;
import Vino.PlayerMarker.PlayerMarkerStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;

class UMusicTunnelSpaceFloatCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
		
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureFireFlies CodyZeroGFeature;
	
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureFireFlies MayZeroGFeature;

	UPROPERTY()
	ULocomotionFeatureZeroGravity MayActualZeroGFeature;

	UPROPERTY()
	ULocomotionFeatureZeroGravity CodyActualZeroGFeature;
	
	AHazePlayerCharacter Player;

	UCameraUserComponent CamUserComp;

	USplineComponent FloatSpline;

	float Distance;
    
	float MovementSpeed = 4500.f;

	float TargetMovementSpeed = 4500.f;

	FHazeAcceleratedRotator CameraEndRotation;

	AMusicTunnelSpaceFloatManager SpaceFloatManager;

	FVector StartYawAxis;

	FVector FinalYawAxis;

	FVector2D SplineOffset;
	FVector2D OffsetVelocity;
	
	const float PlayerOffsetForce = 4500.f;
	float SplinePullForce = 3.f;
	const float Drag = 2.7f;

	UPROPERTY()
	UHazeCameraSettingsDataAsset SpaceFloatCamSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		CamUserComp = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		SpaceFloatManager = Cast<AMusicTunnelSpaceFloatManager>(Game::GetManagerActor(AMusicTunnelSpaceFloatManager::StaticClass(), false));
		Player.DisableOutlineByInstigator(this);
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
        // return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
		// return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject FloatSplineTemp;
		if (ConsumeAttribute(n"FloatSpline", FloatSplineTemp))
		{
			FloatSpline = Cast<USplineComponent>(FloatSplineTemp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplyCameraSettings(SpaceFloatCamSettings, 2.f, this);
		Player == Game::GetCody() ? Player.AddLocomotionFeature(CodyActualZeroGFeature) : Player.AddLocomotionFeature(MayActualZeroGFeature);
		Distance = 0;
		Player.BlockCapabilities(n"Skydive", this);
		Player.BlockCapabilities(n"GroundPound", this);
		Player.BlockCapabilities(n"Dash", this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"PowerfulSong", this);
		Player.BlockCapabilities(n"Cymbal", this);
		Player.BlockCapabilities(CameraTags::Control, this);
		StartYawAxis = CamUserComp.GetYawAxis();
		DisablePlayerMarker(Player, this);
		Niagara::SpawnSystemAttached(SpaceFloatManager.SpaceTrailFX, Player.Mesh, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Skydive", this);
		Player.UnblockCapabilities(n"GroundPound", this);
		Player.UnblockCapabilities(n"Dash", this);
		Player.UnblockCapabilities(n"PowerfulSong", this);
		Player.UnblockCapabilities(n"Cymbal", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(CameraTags::Control, this);
		CamUserComp.SetYawAxis(FVector::UpVector);
		EnablePlayerMarker(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		CamUserComp.SetYawAxis(FVector::UpVector);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Speed along spline
		MovementSpeed = FMath::FInterpTo(MovementSpeed, TargetMovementSpeed, DeltaTime, 0.5f);
		Distance += MovementSpeed * Player.ActorDeltaSeconds;


		FTransform SplineTransform = FloatSpline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		FVector CurrentLocation = Player.GetActorLocation();
		FVector NewLocation = SplineTransform.Location;

		FVector2D OffsetInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		OffsetInput = FVector2D(OffsetInput.Y, OffsetInput.X);

		OffsetVelocity -= OffsetVelocity * Drag * DeltaTime;
		OffsetVelocity += OffsetInput * PlayerOffsetForce * DeltaTime;
		OffsetVelocity -= SplineOffset * SplinePullForce * DeltaTime;
		SplineOffset += OffsetVelocity * DeltaTime;

		NewLocation += SplineTransform.Rotation.RightVector * SplineOffset.X;
		NewLocation += SplineTransform.Rotation.UpVector * SplineOffset.Y;

		if (Player.IsCody())
			NewLocation += SplineTransform.Rotation.RightVector * 100.f;

		if (Player.IsMay())
			NewLocation += SplineTransform.Rotation.RightVector * -100.f;

		FVector PlayerForward = NewLocation - CurrentLocation;
		PlayerForward.Normalize();
		NewLocation = FMath::VInterpTo(CurrentLocation, NewLocation, DeltaTime, 3.f);

				
		//Set camera slowly to correct world upvector
		FinalYawAxis = FMath::VInterpTo(CamUserComp.GetYawAxis(), FVector::UpVector, DeltaTime, 1.f);
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicTunnelSpaceFloat");
		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"ZeroGravity";
		Data.WantedVelocity = FVector(400, 400, 400);
		Player.RequestLocomotion(Data);
	
		FrameMove.ApplyDelta(NewLocation - CurrentLocation);
		
		if(IsActioning(n"LookAtBlackHole"))
		{
			FVector BlackHoleDirection = SpaceFloatManager.BlackHolePOI.ActorLocation - Player.ActorLocation;
			BlackHoleDirection.Normalize();
			MoveComp.SetTargetFacingDirection(BlackHoleDirection, 2.f);
			// FrameMove.SetRotation(Math::MakeQuatFromX(PlayerForward));
		}
		else
		{
			MoveComp.SetTargetFacingDirection(PlayerForward, 2.f);
			// FrameMove.SetRotation(Math::MakeQuatFromX(PlayerForward));
		}

		FrameMove.ApplyTargetRotationDelta();
		
		MoveCharacter(FrameMove, n"AirMovement");
		CamUserComp.SetYawAxis(FinalYawAxis);

		// Print(""+ (FloatSpline.SplineLength - Distance));

		if (FloatSpline.SplineLength - Distance <= 150000)
			SuckPlayerTowardsSpline(DeltaTime);


		if (Player.IsMay())
			SpaceFloatManager.MayDistanceAlongSpline = Distance;
		else		
			SpaceFloatManager.CodyDistanceAlongSpline = Distance;


		if (Player.IsMay() && SpaceFloatManager.MayIsFurtherAlongSpline && !SpaceFloatManager.PlayersAreTogether)
			TargetMovementSpeed = 2850.f;

		if (Player.IsMay() && !SpaceFloatManager.MayIsFurtherAlongSpline && !SpaceFloatManager.PlayersAreTogether)
			TargetMovementSpeed = 6500.f;

		if (Player.IsCody() && !SpaceFloatManager.MayIsFurtherAlongSpline && !SpaceFloatManager.PlayersAreTogether)
			TargetMovementSpeed = 2850.f;

		if (Player.IsCody() && SpaceFloatManager.MayIsFurtherAlongSpline && !SpaceFloatManager.PlayersAreTogether)
			TargetMovementSpeed = 6500.f;

		if (SpaceFloatManager.PlayersAreTogether)
			TargetMovementSpeed = 9500.f;

	}

	void SuckPlayerTowardsSpline(float DeltaTime)
	{
		SplinePullForce += 12.f * DeltaTime;
		SplinePullForce = FMath::Clamp(SplinePullForce, 0.f, 20.f);
	}
}