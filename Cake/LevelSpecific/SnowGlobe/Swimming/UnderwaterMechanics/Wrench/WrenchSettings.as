struct FMagneticWrenchSettings
{
	const float Gravity = 450.f; //450.f
	const float LinearFriction = 1.3f;
	const float AngularFriction = 2.f;

	const float MagnetMinRange = 600.f;
	const float MagnetMaxRange = 1000.f;

	const float MagnetWrenchForce = 650.f;
	const float MagnetPlayerForce = 1200.f;
	const float BothPlayersForceExtra = 1800.f;

	const float AlignMaxAngle = 45.f; //45
	const float AlignMaxDistance = 4000.f; //3000
	const float AlignLinearForce = 2900.f; //2900.f;
	const float AlignLinearDrag = 3.f; //6
	const float AlignAngularForce = 3.6f;

	const float AttachVertMinOffset = 20.f;// * 2.f;
	const float AttachVertMaxOffset = 450.f * 2.f;
	const float AttachHoriOffset = 80.f;

	const float AttachAcceleration_Single = 0.f;
	const float AttachAcceleration_Both = 40.f;
	const float AttachFriction = 2.f;
	const float AttachInterpSpeed = 1.5f;

	const float ScrewCompleteLinearImpulse = 1100.f;
}