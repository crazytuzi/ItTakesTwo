import Cake.Weapons.Recoil.RecoilComponent;
import Vino.Camera.Components.CameraUserComponent;
import Cake.Weapons.RangedWeapon.RangedWeapon;

class URecoilCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	FVector2D RecoilTarget;
	FVector2D RecoilCurrent;
	FVector2D RecoilVelocity;

	FVector2D LastRecoil;

	URecoilComponent Recoil;
	UCameraUserComponent PlayerCameraUser;
	URangedWeaponComponent RangedWeapon;

	float CurrentRecoilSpeed = 1.0f;

	FVector2D AccumulatedInput;

	float AccumulatedInputHorizontalMax = 0.0f;
	float AccumulatedInputHorizontalMin = 0.0f;
	float AccumulatedInputVerticalMax = 0.0f;
	float AccumulatedInputVerticalMin = 0.0f;

	bool bWasFiring = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Recoil = URecoilComponent::Get(Owner);
		RangedWeapon = URangedWeaponComponent::Get(Owner);
		PlayerCameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		if(!RangedWeapon.bFiredBullet)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ApplyRecoil();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	float GetPitchMax() const property
	{
		return (-Recoil.DefaultRecoilSettings.PitchMax) - AccumulatedInputVerticalMax + LastRecoil.Y;
	}

	float GetPitchMin() const property
	{
		return (-Recoil.DefaultRecoilSettings.PitchMin) - AccumulatedInputVerticalMin + LastRecoil.Y;
	}

	float GetYawMax() const property
	{
		return Recoil.DefaultRecoilSettings.YawMax - AccumulatedInputHorizontalMax + LastRecoil.X;
	}

	float GetYawMin() const property
	{
		return Recoil.DefaultRecoilSettings.YawMin - AccumulatedInputHorizontalMin + LastRecoil.X;
	}

	void ApplyRecoil()
	{		
		CurrentRecoilSpeed = Recoil.DefaultRecoilSettings.RecoilSpeed;
		RecoilVelocity = FVector2D::ZeroVector;
		const FVector2D RandomDirection = Math::VRand2D(Recoil.DefaultRecoilSettings.RecoilRangeHorizontalMinimum, Recoil.DefaultRecoilSettings.RecoilRangeHorizontalMaximum, Recoil.DefaultRecoilSettings.RecoilRangeVerticalMinimum, Recoil.DefaultRecoilSettings.RecoilRangeVerticalMaximum).GetSafeNormal();
		
		FVector2D RecoilDirection = (RandomDirection * (Recoil.DefaultRecoilSettings.RecoilDistance * Recoil.RecoilDistanceMultiplier));

		if((RecoilCurrent.Y + RecoilDirection.Y) <= PitchMax || (RecoilCurrent.Y + RecoilDirection.Y) >= PitchMin)
		{
			RecoilDirection.Y *= -1.0f;
		}

		if((RecoilCurrent.X + RecoilDirection.X) <= YawMin || (RecoilCurrent.X + RecoilDirection.X) >= YawMax)
		{
			RecoilDirection.X *= -1.0f;
		}

		RecoilTarget = RecoilCurrent + RecoilDirection;
		
		Recoil.BulletCount++;
		Recoil.TimeSinceLastBulletWasFired = 0.0f;
	}

	FVector2D UpdateRecoil(float DeltaTime)
	{
		const FVector2D Distance = RecoilTarget - RecoilCurrent;
		RecoilVelocity += Distance * DeltaTime;
		FVector2D RecoilMovement = RecoilVelocity * CurrentRecoilSpeed * DeltaTime;

		RecoilCurrent += RecoilMovement;

		if(Distance.DotProduct(RecoilTarget - RecoilCurrent) < 0.05f)
		{
			RecoilCurrent = RecoilTarget;

			if(!RangedWeapon.IsFiring())
			{
				if(Recoil.DefaultRecoilSettings.bReturnToVerticalOrigin)
				{
					if(RecoilCurrent.Y > 0.0f && AccumulatedInputVerticalMin < 0.0f)
					{
						RecoilCurrent.Y = FMath::Max(RecoilCurrent.Y + AccumulatedInputVerticalMin, 0.0f);
					}
					else if(RecoilCurrent.Y < 0.0f && AccumulatedInputVerticalMax > 0.0f)
					{
						RecoilCurrent.Y = FMath::Max(RecoilCurrent.Y - AccumulatedInputVerticalMax, 0.0f);
					}
				}

				if(Recoil.DefaultRecoilSettings.bReturnToHorizontalOrigin)
				{
					if(RecoilCurrent.X > 0.0f && AccumulatedInputHorizontalMax < 0.0f)
					{
						RecoilCurrent.X = FMath::Max(RecoilCurrent.X + AccumulatedInputHorizontalMax, 0.0f);
					}
					else if(RecoilCurrent.X < 0.0f && AccumulatedInputHorizontalMin > 0.0f)
					{
						RecoilCurrent.X = FMath::Max(RecoilCurrent.X - AccumulatedInputHorizontalMin, 0.0f);
					}
				}

				ZeroAccumulatedInput();
			}

			RecoilVelocity = FVector2D::ZeroVector;

			FVector2D NewRecoilTarget = FVector2D::ZeroVector;

			if(!Recoil.DefaultRecoilSettings.bReturnToVerticalOrigin)
			{
				NewRecoilTarget.Y = RecoilCurrent.Y;
			}

			if(!Recoil.DefaultRecoilSettings.bReturnToHorizontalOrigin)
			{
				NewRecoilTarget.X = RecoilCurrent.X;
			}

			RecoilTarget = NewRecoilTarget;
			//LastRecoil = RecoilTarget;
			CurrentRecoilSpeed = Recoil.DefaultRecoilSettings.RecoilRecover;

			return Distance;
		}

		return RecoilMovement;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!HasControl() || PlayerCameraUser == nullptr)
		{
			return;
		}

		//Print("LastRecoil.X " + LastRecoil.X);

		Recoil.IncrementTime(DeltaTime);

		//Print("AccumulatedInputVerticalMax " + AccumulatedInputVerticalMax);
		//Print("Recoil.bIsFiring " + Recoil.bIsFiring);

		//Print("AccumulatedInputHorizontalMin " + AccumulatedInputHorizontalMin);
		//Print("AccumulatedInputHorizontalMax " + AccumulatedInputHorizontalMax);
		//Print("YawMin " + YawMin);
		//Print("RecoilCurrent.X " + RecoilCurrent.X);

		if(RangedWeapon.IsFiring())
		{
			AccumulatedInput += GetInputCompensation();
			const FVector2D Input = GetInputCompensation();

			const float InputScalar = 1.0f;//Recoil.DefaultRecoilSettings.RecoilDistance;
			if(Input.X < 0.0f)
			{
				AccumulatedInputHorizontalMax += Input.X * InputScalar;
			}
			else if(Input.X > 0.0f)
			{
				AccumulatedInputHorizontalMin += Input.X * InputScalar;
			}

			if(Input.Y > 0.0f)
			{
				AccumulatedInputVerticalMax += Input.Y * InputScalar;
				//Print("Bleh");
			}
			else if(Input.Y < 0.0f)
			{
				AccumulatedInputVerticalMin += Input.Y * InputScalar;
			}
		}

		FVector2D RecoilMovement = UpdateRecoil(DeltaTime);
		PlayerCameraUser.AddDesiredRotation(FRotator(RecoilMovement.Y, RecoilMovement.X, 0.0f));

		// Read fire rate from somewhere
		if(IsKickAlmostZero() && Recoil.TimeSinceLastBulletWasFired > 0.1f)
		{
			Recoil.BulletCount = 0;
		}

		if(bWasFiring && !RangedWeapon.IsFiring())
		{
			LastRecoil = RecoilTarget;
		}

		Recoil.TimeSinceLastBulletWasFired += DeltaTime;
		bWasFiring = RangedWeapon.IsFiring();
	}

	void ZeroAccumulatedInput()
	{
		AccumulatedInput = FVector2D::ZeroVector;
		AccumulatedInputHorizontalMax = 0.0f;
		AccumulatedInputHorizontalMin = 0.0f;
		AccumulatedInputVerticalMax = 0.0f;
		AccumulatedInputVerticalMin = 0.0f;
	}

	bool IsKickAlmostZero() const
	{
		return (RecoilTarget - RecoilCurrent).IsNearlyZero();
	}

	FVector2D GetInputCompensation() const property
	{
		return GetAttributeVector2D(AttributeVectorNames::CameraDirection);
	}
}

