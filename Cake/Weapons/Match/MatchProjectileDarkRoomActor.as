
import Vino.Combustible.CombustibleComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.Weapons.Match.MatchProjectileActor;

UCLASS(abstract)
class AMatchProjectileDarkRoomActor : AMatchProjectileActor 
{
	/* Magnitude of the impulse helper */
	UPROPERTY(Category = "Match Physics")
 	float MinimumUpImpulse = 2000.f;

	/* 
		The Impulse helper is at its strongest when you are aiming Horizontally.
		We'll lerp away from the helper as you start aiming UP or DOWN.

		Value = 0 Will turn of the OFF the Helper, Only using the actual impulse.
		Value = 1  Makes the blend linear.
		Values < 1 Lerps to the Actual Impulse sooner. 
		Values > 1 Lerps to the Actual impulse later.

		https://www.wolframalpha.com/input/?i=plot+y+%3D+x%5E0.2,+x+from+0+to+1
	*/
	UPROPERTY(Category = "Match Physics")
	float LerpRamp = 0.2f;

	void ApplyLaunchImpulse(FVector ShootDirection)
	{
		// !!! Important that we reset the velocity before adding impulses.
		Velocity = FVector::ZeroVector;

		//////////////////////////////////////////////////////////////////////////
		// Horizontal Impulse
		const FVector ShootDirection_Horizontal = ShootDirection.VectorPlaneProject(FVector::UpVector);
		const FVector Impulse_Horizontal = ShootDirection_Horizontal * InitialLaunchImpulse;
		Velocity += Impulse_Horizontal;

		//////////////////////////////////////////////////////////////////////////
		// Calculate Lerp fraction
		const float PointingUpFraction = FMath::Abs(ShootDirection.DotProduct(FVector::UpVector));
		const float PointingUpFraction_Ramped = FMath::Pow(PointingUpFraction, LerpRamp);

		//////////////////////////////////////////////////////////////////////////
		// Vertical Impulse
		const FVector Impulse_Vertical = ShootDirection.ProjectOnToNormal(FVector::UpVector) * InitialLaunchImpulse;
		const FVector HelpImpulse_Vertical = FVector::UpVector * MinimumUpImpulse;
		const FVector LerpedImpulse_Vertical = FMath::Lerp(HelpImpulse_Vertical, Impulse_Vertical, PointingUpFraction_Ramped);
		Velocity += LerpedImpulse_Vertical;

//  		Print("PointingUpFractionRamped: " + PointingUpFraction_Ramped, Duration = 1.f);
//  		Print("Impulse Size: " + Velocity.Size(), Duration = 1.f);
// 
//  		System::DrawDebugLine(
// 			LaunchLocation,
// 			LaunchLocation + ShootDirection * 50000.f,
// 			FLinearColor::Blue,
// 			5.f,
// 			5.f
// 		);

	}

};