const User = require('../models/User');

// @desc    Update user profile
// @route   PUT /api/v1/profile
// @access  Private
exports.updateProfile = async (req, res, next) => {
  try {
    const { name, email, phoneNumber } = req.body;

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.name = name || user.name;
    user.email = email || user.email;
    user.phoneNumber = phoneNumber || user.phoneNumber;

    if (req.file) {
      // Store relative path for serving via static files
      user.profileImage = `/api/v1/profile_pictures/${req.file.filename}`;
    }

    await user.save();

    res.status(200).json({
      success: true,
      data: {
        ...user.toObject(),
        profileImage: user.profileImage
      }
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
};