import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelVehicle;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelFeature;

class UMusicTunnelVehicleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	FHazeAcceleratedRotator CameraEndRotation;

	AHazePlayerCharacter Player;
	AMusicTunnelVehicle Vehicle;
	UHazeActiveCameraUserComponent CamUserComp;

	ULocomotionFeatureMusicTunnel MusicTunnelFeat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CamUserComp = UHazeActiveCameraUserComponent::Get(Owner);
		CameraEndRotation.SnapTo(FVector::UpVector.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AMusicTunnelVehicle TempVehicle = Cast<AMusicTunnelVehicle>(GetAttributeObject(n"Vehicle"));

		if(TempVehicle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(n"MusicTunnelVehicle"))
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"ShouldDeactivateMusicTunnel"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Vehicle == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		UObject TempVehicle = nullptr;
		ConsumeAttribute(n"Vehicle", TempVehicle);
		OutParams.AddObject(n"Vehicle", TempVehicle);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Vehicle = Cast<AMusicTunnelVehicle>(ActivationParams.GetObject(n"Vehicle"));

		//Maybe change this to  VehicleRoot instead of VehicleMesh, since we rotate the mesh in animation
		CameraEndRotation.SnapTo(Vehicle.VehicleMesh.UpVector.Rotation());
		
		Vehicle.VehicleMesh.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::SnapToTarget);

		MusicTunnelFeat = Player.IsCody() ? Vehicle.CodyFeature : Vehicle.MayFeature;

		Player.AddLocomotionFeature(MusicTunnelFeat);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.AttachToComponent(Vehicle.VehicleRoot);
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 0.f;
		Player.ApplyCameraSettings(Vehicle.CamSettings, CamBlend, this, EHazeCameraPriority::Medium);
		Player.Mesh.RemoveOutlineFromMesh(this);
		Player.SetActorRelativeLocation(FVector(0.f, 0.f, 25.f), false, FHitResult(), true);
		Player.BlockCapabilities(n"Cymbal", this);
		Player.BlockCapabilities(n"WeaponAim", this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"PowerfulSong", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Vehicle.StopMoving();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Vehicle.VehicleMesh.DetachFromComponent();
		Player.Mesh.AddMeshToPlayerOutline(Player, this);
		Player.ClearFieldOfViewByInstigator(this);
		Player.ClearIdealDistanceByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(n"Cymbal", this);
		Player.UnblockCapabilities(n"WeaponAim", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(n"PowerfulSong", this);
		Player.RemoveLocomotionFeature(MusicTunnelFeat);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		CamUserComp.SetYawAxis(FVector::UpVector);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Vehicle != nullptr)
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			Vehicle.CurrentInput = -Input.X;

			float BlendSpaceYValue = FMath::Lerp(-1.f, 1.f, Vehicle.SyncedSpeedFraction.Value);
			Player.SetAnimFloatParam(n"InputX", Input.X);
			Player.SetAnimFloatParam(n"SpeedFraction", Vehicle.SyncedSpeedFraction.Value);
			Vehicle.SetCapabilityAttributeValue(n"MusicTunnelVehicleAudioTurning", Input.X);

			float CurveValue = Vehicle.FieldOfViewCurve.GetFloatValue(Vehicle.SyncedSpeedFraction.Value);
			float CurFoV = FMath::Lerp(60.f, 80.f, CurveValue);
			float CurIdealDistance = FMath::Lerp(650.f, 800.f, CurveValue);

			FHazeCameraBlendSettings CamBlend;
			CamBlend.BlendTime = 0.5f;
			Player.ApplyFieldOfView(CurFoV, CamBlend, this, EHazeCameraPriority::Medium);
			Player.ApplyIdealDistance(CurIdealDistance, CamBlend, this, EHazeCameraPriority::Medium);

			CameraEndRotation.SnapTo(Vehicle.VehicleMesh.UpVector.Rotation());

			FHazeRequestLocomotionData LocoData;
			LocoData.AnimationTag = n"MusicTunnel";
			Player.RequestLocomotion(LocoData);

			if (CamUserComp != nullptr)
				CamUserComp.SetYawAxis(Vehicle.VehicleRoot.UpVector);

		}
	}
}
