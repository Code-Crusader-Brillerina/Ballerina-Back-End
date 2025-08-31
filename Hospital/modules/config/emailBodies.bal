public function sendOTPEmail(string otp) returns json {
    string subject = "Your One-Time Password (OTP) for Halgoes Hospital";

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Halgoes Hospital Security Verification</h2>
            <p>Dear User,</p>
            <p>To complete your verification, please use the following One-Time Password (OTP):</p>
            
            <div style="font-size: 22px; font-weight: bold; color: #D35400; margin: 20px 0;">
              ${otp}
            </div>

            <p>This OTP is valid for <b>5 minutes</b>. Please do not share this code with anyone.</p>
            
            <p>If you did not request this, please ignore this email or contact our support team immediately.</p>
            
            <p>Best Regards,<br>
            <b>Halgoes Hospital Security Team</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}


public function addDoctorEmail(string username,string email,string password)returns json{
    string subject = string `Welcome to Halgoes hospital Your Doctor Account is Ready`;

    string message=string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Welcome to Halgoes hospital</h2>
            <p>Dear Dr. ${username},</p>
            <p>Your doctor account has been successfully created in our system.</p>

            <h3>Account Details:</h3>
            <ul>
              <li><b>Email:</b> ${email}</li>
              <li><b>Password:${password}</b> (the one admin set during registration)</li>
            </ul>

            <p>Please log in to your dashboard and remember to change your password after your first login.</p>
            <p>If you have any questions, feel free to contact our support team.</p>

            <p>Best Regards,<br>
            <b>Halgoes hospital Administration</b></p>
          </body>
        </html>
    `;
    return {
        "subject":subject,
        "message":message
    };
}

public function addPharmacyEmail(string pharmacyName, string email, string password) returns json {
    string subject = "Welcome to Halgoes Hospital – Your Pharmacy Account is Ready";

    string message =string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Welcome to Halgoes Hospital</h2>
            <p>Dear ${pharmacyName},</p>
            <p>Your pharmacy account has been successfully created in our system.</p>

            <h3>Account Details:</h3>
            <ul>
              <li><b>Email:</b> ${email}</li>
              <li><b>Password:</b> ${password} (the one admin set during registration)</li>
            </ul>

            <p>Please log in to your pharmacy dashboard and remember to change your password after your first login.</p>
            <p>If you have any questions, feel free to contact our support team.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}

public function deleteDoctorEmail(string username, string email) returns json {
    string subject = string `Halgoes Hospital – Doctor Account Deleted`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #C0392B;">Halgoes Hospital</h2>
            <p>Dear Dr. ${username},</p>
            <p>We would like to inform you that your doctor account associated with the email <b>${email}</b> has been removed from our system.</p>

            <p>If you believe this was a mistake or need further clarification, please contact our administration team immediately.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}

public function deletePharmacyEmail(string pharmacyName, string email) returns json {
    string subject = string `Halgoes Hospital – Pharmacy Account Deleted`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #C0392B;">Halgoes Hospital</h2>
            <p>Dear ${pharmacyName},</p>
            <p>We would like to inform you that your pharmacy account associated with the email <b>${email}</b> has been removed from our system.</p>

            <p>If you believe this was a mistake or need further clarification, please contact our administration team immediately.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}

public function paymentEmail(string username, string email, string amount, string date, string invoiceId) returns json {
    string subject = string `Halgoes Hospital – Payment Confirmation (Invoice #${invoiceId})`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #27AE60;">Payment Confirmation</h2>
            <p>Dear ${username},</p>
            <p>We have received your payment successfully. Below are the details of your transaction:</p>

            <h3>Payment Details:</h3>
            <ul>
              <li><b>Invoice ID:</b> ${invoiceId}</li>
              <li><b>Amount:</b> ${amount}</li>
              <li><b>Date:</b> ${date}</li>
              <li><b>Email:</b> ${email}</li>
            </ul>

            <p>Thank you for your payment. Please keep this email as confirmation for your records.</p>
            <p>If you have any questions regarding this payment, please contact our billing department.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Finance Team</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}


public function sendConfirmationEmail(string otp) returns json {
    string subject = "Confirm Your Email for Halgoes Hospital";

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Welcome to Halgoes Hospital!</h2>
            <p>Dear User,</p>
            <p>Thank you for registering. Please use the following One-Time Password (OTP) to confirm your email address and activate your account:</p>
            
            <div style="font-size: 22px; font-weight: bold; color: #D35400; margin: 20px 0;">
              ${otp}
            </div>

            <p>This OTP is valid for <b>10 minutes</b>. If you did not create an account, please disregard this email.</p>
            
            <p>Best Regards,<br>
            <b>The Halgoes Hospital Team</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}


public function patientAppointmentConfirmationEmail(string patientName, string doctorName, string date, string 'time, int queueNumber, string url) returns json {
    string subject = "Your Appointment is Confirmed with Dr. " + doctorName;
    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Halgoes Hospital - Appointment Confirmation</h2>
            <p>Dear ${patientName},</p>
            <p>Your appointment has been successfully scheduled and paid for. Please find the details below:</p>
            <h3>Appointment Details:</h3>
            <ul>
              <li><b>Doctor:</b> Dr. ${doctorName}</li>
              <li><b>Date:</b> ${date}</li>
              <li><b>Time Slot:</b> ${'time}</li>
              <li><b>Your Queue Number:</b> ${queueNumber}</li>
            </ul>
            <p>Please use the following link to join the video consultation at your scheduled time:</p>
            <a href="${url}" style="display: inline-block; padding: 10px 20px; background-color: #27AE60; color: #ffffff; text-decoration: none; border-radius: 5px;">Join Meeting</a>
            <p>Best Regards,<br><b>The Halgoes Hospital Team</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}

public function doctorAppointmentNotificationEmail(string doctorName, string patientName, string date, string 'time, int queueNumber, string url) returns json {
    string subject = "New Appointment Scheduled with " + patientName;
    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Halgoes Hospital - New Appointment Notification</h2>
            <p>Dear Dr. ${doctorName},</p>
            <p>A new appointment has been scheduled with a patient. Please see the details below:</p>
            <h3>Appointment Details:</h3>
            <ul>
              <li><b>Patient:</b> ${patientName}</li>
              <li><b>Date:</b> ${date}</li>
              <li><b>Time Slot:</b> ${'time}</li>
              <li><b>Queue Number:</b> ${queueNumber}</li>
            </ul>
            <p>The video consultation link for this appointment is:</p>
            <a href="${url}" style="display: inline-block; padding: 10px 20px; background-color: #1E88E5; color: #ffffff; text-decoration: none; border-radius: 5px;">Meeting Link</a>
            <p>Best Regards,<br><b>Halgoes Hospital Administration</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}

// Add this function to the end of your utils.bal file

public function patientPrescriptionNotificationEmail(string patientName, string doctorName, string prescriptionId) returns json {
    string subject = "Your New Prescription from Dr. " + doctorName + " is Ready";
    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Halgoes Hospital - Prescription Notification</h2>
            <p>Dear ${patientName},</p>
            <p>A new prescription has been issued for you by Dr. ${doctorName}.</p>
            <p>You can view the details and order your medication by logging into your patient portal.</p>
            <p><b>Prescription ID:</b> ${prescriptionId}</p>
            <p>Please follow your doctor's instructions carefully.</p>
            <p>Best Regards,<br><b>The Halgoes Hospital Team</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}